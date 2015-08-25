public with sharing class configCtl extends html5tCtl {
    private class sexception extends exception {}

    @remoteAction
    public static config__c get_config(){
        return config__c.getOrgDefaults();
    }

    // NEED TEST
    public static blob get_private_key(){
        secure_config__c sconfig = secure_config__c.getOrgDefaults();
        if (sconfig.private_key__c == null){
            sconfig.private_key__c = EncodingUtil.base64Encode(Crypto.generateAesKey(128));
            upsert sconfig;
        }
        return EncodingUtil.base64Decode(sconfig.private_key__c);
    } 
}