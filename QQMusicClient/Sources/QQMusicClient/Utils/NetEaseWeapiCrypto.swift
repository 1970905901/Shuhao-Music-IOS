import Foundation
import CCommonCrypto
import Security

/// 网易云音乐 weapi 加密（AES-128-CBC + RSA），参考公开实现移植
enum NetEaseWeapiCrypto {
    private static let modulusHex = "00e0b509f6259df8642dbc35662901477df22677ec152b5ff68ace615bb7b725152b3ab17a876aea8a5aa76d2e417629ec4ee341f56135fccf695280104e0312ecbda92557c93870114af6c9d05c4f7f0c3685b7a46bee255932575cce10b424d813cfe4875d3e82047b97ddef52741d546b8e289dc6935b3ece0462db0a22b8e7"
    private static let pubKeyHex = "010001"
    private static let nonce = "0CoJUm6Qyw8W8jud"
    private static let iv = "0102030405060708"

    /// 将请求参数字典加密为 weapi 所需的 params / encSecKey
    static func encryptedParams(for payload: [String: Any]) -> [String: String] {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: .sortedKeys),
              let text = String(data: jsonData, encoding: .utf8) else {
            return [:]
        }

        let secretKey = randomSecretKey(length: 16)
        let firstPass = aesEncrypt(text: text, key: nonce) ?? ""
        let params = aesEncrypt(text: firstPass, key: secretKey) ?? ""
        let encSecKey = rsaEncrypt(secretKey: secretKey)
        return ["params": params, "encSecKey": encSecKey]
    }

    // MARK: - AES

    private static func randomSecretKey(length: Int) -> String {
        let chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).compactMap { _ in chars.randomElement() })
    }

    private static func aesEncrypt(text: String, key: String) -> String? {
        guard let data = text.data(using: .utf8),
              let keyData = key.data(using: .utf8),
              let ivData = iv.data(using: .utf8) else { return nil }

        let cryptLength = data.count + kCCBlockSizeAES128
        var cryptData = Data(count: cryptLength)
        var numBytesEncrypted: size_t = 0

        let status = cryptData.withUnsafeMutableBytes { cryptBytes -> CCCryptorStatus in
            data.withUnsafeBytes { dataBytes -> CCCryptorStatus in
                ivData.withUnsafeBytes { ivBytes -> CCCryptorStatus in
                    keyData.withUnsafeBytes { keyBytes -> CCCryptorStatus in
                        CCCrypt(
                            CCOperation(kCCEncrypt),
                            CCAlgorithm(kCCAlgorithmAES128),
                            CCOptions(kCCOptionPKCS7Padding),
                            keyBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                            kCCKeySizeAES128,
                            ivBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                            dataBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                            data.count,
                            cryptBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                            cryptLength,
                            &numBytesEncrypted
                        )
                    }
                }
            }
        }

        guard status == kCCSuccess else { return nil }
        cryptData.count = numBytesEncrypted
        return cryptData.base64EncodedString()
    }

    // MARK: - RSA

    private static func rsaEncrypt(secretKey: String) -> String {
        let reversedData = Data(secretKey.utf8.reversed())
        guard reversedData.count <= 256 else { return "" }

        var padded = Data(count: 256)
        let start = 256 - reversedData.count
        padded.replaceSubrange(start..<256, with: reversedData)

        guard let publicKey = createPublicKey() else { return "" }
        var error: Unmanaged<CFError>?
        guard let cipherData = SecKeyCreateEncryptedData(publicKey, .rsaEncryptionRaw, padded as CFData, &error) as Data? else {
            return ""
        }
        return cipherData.map { String(format: "%02x", $0) }.joined()
    }

    private static func createPublicKey() -> SecKey? {
        let modulus = dataFromHex(modulusHex)
        let exponent = dataFromHex(pubKeyHex)

        let modulusEncoded = asn1Integer(modulus)
        let exponentEncoded = asn1Integer(exponent)
        let rsaPublicKey = asn1Sequence(modulusEncoded + exponentEncoded)

        let algorithmIdentifier = asn1Sequence(Data([0x06, 0x09, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00]))
        let bitString = Data([0x03]) + asn1Length(rsaPublicKey.count + 1) + Data([0x00]) + rsaPublicKey
        let spki = asn1Sequence(algorithmIdentifier + bitString)

        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
            kSecAttrKeySizeInBits as String: 2048
        ]
        return SecKeyCreateWithData(spki as CFData, attributes as CFDictionary, nil)
    }

    // MARK: - ASN.1 helpers

    private static func asn1Sequence(_ content: Data) -> Data {
        Data([0x30]) + asn1Length(content.count) + content
    }

    private static func asn1Integer(_ value: Data) -> Data {
        var data = value
        if data.first.map({ $0 & 0x80 != 0 }) == true {
            data.insert(0x00, at: 0)
        }
        return Data([0x02]) + asn1Length(data.count) + data
    }

    private static func asn1Length(_ length: Int) -> Data {
        if length < 128 {
            return Data([UInt8(length)])
        }
        var bytes = Data()
        var remaining = length
        while remaining > 0 {
            bytes.insert(UInt8(remaining & 0xff), at: 0)
            remaining >>= 8
        }
        bytes.insert(0x80 | UInt8(bytes.count), at: 0)
        return bytes
    }

    private static func dataFromHex(_ hex: String) -> Data {
        var data = Data()
        var index = hex.startIndex
        while index < hex.endIndex {
            let nextIndex = hex.index(index, offsetBy: 2, limitedBy: hex.endIndex) ?? hex.endIndex
            if let byte = UInt8(hex[index..<nextIndex], radix: 16) {
                data.append(byte)
            }
            index = nextIndex
        }
        return data
    }
}
