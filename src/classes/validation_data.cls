@isTest
public with sharing class validation_data {
    public static Session__c createDummySession(String session_name, String who_can_submit_survey, String who_can_get_handout) {
        Session__c session = new Session__c(
            name = session_name,
            date__c = date.valueOf('2012-09-30'),
            who_can_submit_survey__c = who_can_submit_survey,
            Post_To_Account_Record_Feed__c = false,
            Post_To_Contact_Record_Feed__c = false
        );
        insert session;

        //create dummy guest
        guest__c guest1 = new guest__c(status__c = 'submitted', session__c=session.id, last_name__c='test guest1', email__c='hoge1@hoge.com', first_name__c='uruffjjfr', title__c='rufhbrfjjf', company__c='jfjieerjfkf');
        guest__c guest2 = new guest__c(status__c = 'submitted', session__c=session.id, last_name__c='test guest2', email__c='hoge2@hoge.com');
        guest__c guest3 = new guest__c(status__c = 'submitted', session__c=session.id, last_name__c='test guest3', email__c='hoge3@hoge.com');
        guest__c guest4 = new guest__c(status__c = 'submitted', session__c=session.id, last_name__c='test guest4', email__c='hoge4@hoge.com');
        guest__c guest5 = new guest__c(status__c = 'submitted', session__c=session.id, last_name__c='test guest5', email__c='hoge5@hoge.com');
        guest__c guest6 = new guest__c(session__c=session.id, last_name__c='test guest6', email__c='hoge6@hoge.com');
        insert guest1;
        insert guest2;
        insert guest3;
        insert guest4;
        insert guest5;
        insert guest6;
        
        //create dummy question
        custom_survey_question__c csq1 = new custom_survey_question__c(session__c=session.id, question__c='test question1');
        insert csq1;
        
        //create dummy option
        custom_survey_option__c cso1 = new custom_survey_option__c(session__c=session.id, custom_survey_question__c=csq1.id, option__c='test option1');
        custom_survey_option__c cso2 = new custom_survey_option__c(session__c=session.id, custom_survey_question__c=csq1.id, option__c='test option2');
        insert cso1;
        insert cso2;
        
        //create dummy answer
        custom_survey_answer__c csa1 = new custom_survey_answer__c(session__c=session.id, guest__c=guest1.id, custom_survey_option__c=cso1.id);
        custom_survey_answer__c csa2 = new custom_survey_answer__c(session__c=session.id, guest__c=guest1.id, custom_survey_option__c=cso2.id);
        custom_survey_answer__c csa3 = new custom_survey_answer__c(session__c=session.id, guest__c=guest2.id, custom_survey_option__c=cso1.id);
        insert csa1;
        insert csa2;
        insert csa3;
        
        return session;
    }
}