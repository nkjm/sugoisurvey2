public with sharing class security {
    public static string encrypt(string plainText){
    	string encText = EncodingUtil.base64Encode(Crypto.encryptWithManagedIV('AES128', configCtl.get_private_key(), Blob.valueOf(plainText)));
        return encText;
    }
    
    public static string decrypt(string encText){
    	string plainText = Crypto.decryptWithManagedIV('AES128', configCtl.get_private_key(), EncodingUtil.base64Decode(encText)).toString();
        return plainText;
    }
}