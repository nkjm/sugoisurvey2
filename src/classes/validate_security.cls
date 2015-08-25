@isTest
public with sharing class validate_security {
    public static void test_encrypt_and_decrypt(){
        session__c s = new session__c(name = 'saldjflasjdfasdf');
        s = sessionCtl.create_session(s);
        string encId = security.encrypt(s.id);
        string plainId = security.decrypt(encId);
        system.assertEquals(s.Id, plainId);
    }
}