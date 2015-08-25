@isTest
public with sharing class validate_cron_trigger {
    
    private static testmethod void validate_execute(){
        list<session__c> sessions = validate_link_to_contact.create_sessions();
        validate_link_to_contact.create_account_and_contacts();
        guest__c g;
        list<feedItem> feedItems;
        
        config__c config = new config__c(survey_sites_domain__c = 'sugoisurvey5-developer-edition.ap0.force.com');
        upsert config;
        
        User u = [select id from User where username = 'sugoisurvey@sugoisurvey5-developer-edition.ap0.force.com'];
        System.runAs(u){
            g = new guest__c();
            g.email__c = 'aoeifioj@hoge.com';
            g.session__c = sessions[0].id;
            insert g;
        }
        
        list<guest__c> guests = [select to_be_posted_to_record_feed__c from guest__c where session__c = :sessions[0].id];
        system.assertEquals(1, guests.size());
        system.assertEquals(true, guests[0].to_be_posted_to_record_feed__c);
        
        string sch = '0 0 * * * ?';
        Test.startTest();
        System.schedule('Sugoi Survey Cron Trigger for Validate', sch, new cron_trigger());
        Test.stopTest();

        guests = [select to_be_posted_to_record_feed__c from guest__c where session__c = :sessions[0].id];
        system.assertEquals(false, guests[0].to_be_posted_to_record_feed__c);
    }
}