@isTest
public with sharing class validate_ManCtl {
    private static testmethod void validate_generate_config(){
        list<site> sites = [select status, subdomain from site where urlPathPrefix = 'sugoisurvey'];
        string subdomain = sites[0].subdomain;
        config__c config;

        /*
        initialized => true
        need re-initialization => false
        */
        config = config__c.getOrgDefaults();
        config.initialized__c = true;
        config.need_re_initialization__c = false;
        upsert config;
        try {
            ManCtl.generate_config('https://sugoisurvey4.na12.visual.force.com');
        } catch (Exception e){
            system.assertEquals(system.label.already_initialized, e.getMessage());
        }
        
        /*
        initialized => true
        need re-initialization => true
        */
        config = config__c.getOrgDefaults();
        config.initialized__c = true;
        config.need_re_initialization__c = true;
        upsert config;
        ManCtl.generate_config('https://sugoisurvey4.na12.visual.force.com');     

        /* Case #1
        Initialized => false
        Edition => DE
        Sandbox => false
        MyDomain => false
        */
        ManCtl.generate_config('https://sugoisurvey4.na12.visual.force.com/apex/init');
        system.assertEquals(false, config__c.getOrgDefaults().sandbox__c);
        system.assertEquals(null, config__c.getOrgDefaults().sandbox_name__c);
        system.assertEquals(false, config__c.getOrgDefaults().my_domain_enabled__c);
        system.assertEquals(null, config__c.getOrgDefaults().my_domain__c);
        system.assertEquals('na12', config__c.getOrgDefaults().instance__c);
        
        system.assertEquals(subdomain + '.' + config__c.getOrgDefaults().instance__c + '.force.com', config__c.getOrgDefaults().survey_sites_domain__c);
        system.assertEquals('https://' + config__c.getOrgDefaults().survey_sites_domain__c + '/sugoisurvey/', config__c.getOrgDefaults().survey_sites_url__c);
        system.assertEquals('sugoisurvey@' + config__c.getOrgDefaults().survey_sites_domain__c, config__c.getOrgDefaults().sites_username__c);
        
        
        /* Case #2
        Initialized => false
        Edition => DE
        Sandbox => true
        MyDomain => false
        */
        ManCtl.generate_config('https://sugoisurvey4.cs5.visual.force.com/apex/init');
        system.assertEquals(true, config__c.getOrgDefaults().sandbox__c);
        list<string> divided_username = UserInfo.getUsername().split('\\.',0);
        system.assertEquals(divided_username[divided_username.size() - 1], config__c.getOrgDefaults().sandbox_name__c);
        system.assertEquals(false, config__c.getOrgDefaults().my_domain_enabled__c);
        system.assertEquals(null, config__c.getOrgDefaults().my_domain__c);
        system.assertEquals('cs5', config__c.getOrgDefaults().instance__c);
        
        system.assertEquals(subdomain + '.' + config__c.getOrgDefaults().sandbox_name__c + '.' + config__c.getOrgDefaults().instance__c + '.force.com', config__c.getOrgDefaults().survey_sites_domain__c);
        system.assertEquals('https://' + config__c.getOrgDefaults().survey_sites_domain__c + '/sugoisurvey/', config__c.getOrgDefaults().survey_sites_url__c);
        system.assertEquals('sugoisurvey@' + config__c.getOrgDefaults().survey_sites_domain__c, config__c.getOrgDefaults().sites_username__c);
        
        
        /* Case #3
        Initialized => false
        Edition => DE
        Sandbox => true
        MyDomain => true
        */
        ManCtl.generate_config('https://japan-isv--japanisv--sugoisurvey4.cs6.visual.force.com/apex/init');
        system.assertEquals(true, config__c.getOrgDefaults().sandbox__c);
        system.assertEquals('japanisv', config__c.getOrgDefaults().sandbox_name__c);
        system.assertEquals(true, config__c.getOrgDefaults().my_domain_enabled__c);
        system.assertEquals('japan-isv', config__c.getOrgDefaults().my_domain__c);
        system.assertEquals('cs6', config__c.getOrgDefaults().instance__c);
        
        system.assertEquals(subdomain + '.' + config__c.getOrgDefaults().sandbox_name__c + '.' + config__c.getOrgDefaults().instance__c + '.force.com', config__c.getOrgDefaults().survey_sites_domain__c);
        system.assertEquals('https://' + config__c.getOrgDefaults().survey_sites_domain__c + '/sugoisurvey/', config__c.getOrgDefaults().survey_sites_url__c);
        system.assertEquals('sugoisurvey@' + subdomain + '.force.com.' + config__c.getOrgDefaults().sandbox_name__c, config__c.getOrgDefaults().sites_username__c);
    }

    private static testmethod void validate_assign_permission_set(){
        config__c config;
        /*
        Negative Case #1
        config.survey_sites_domain__c = null
        */
        try {
            ManCtl.assign_permission_set();
        } catch (Exception e){
            system.assertEquals(system.label.sites_not_activated, e.getMessage());
        }
        
        /*
        Negative Case #2
        sites_user not found
        */
        config = config__c.getOrgDefaults();
        config.survey_sites_domain__c = 'sugoisurvey4-developer-edition.na11.force.com';
        upsert config;
        list<user> site_users = [select id, username from user where username like 'sugoisurvey@%'];
        
        try {
            ManCtl.assign_permission_set();
        } catch (Exception e){
            system.assertEquals(system.label.sites_user_not_found, e.getMessage());
        }
        
        /*
        string sites_user_username = 'sugoisurvey@sugoisurvey-developer-edition.na14.force.com';
        id sites_user_id = [select id from user where username = :sites_user_username].id;
        id sites_permission_set_id = [select id from permissionSet where name = 'Sugoi_Survey_Sites_for_Any_License'].id;
        system.assertEquals(1, [select id from permissionSetAssignment where assigneeId = :sites_user_id and permissionSetId = :sites_permission_set_id].size());
        */
    }

    private static testmethod void validate_start_cron(){
        config__c config = config__c.getOrgDefaults();
        config.initialized__c = false;
        upsert config;
        
        /*
        Positive Case #1
        initialized = false
        */
        ManCtl.start_cron();
        system.assertEquals(true, config__c.getOrgDefaults().initialized__c);
        
        /*
        Negative Case #1
        initialized = true
        */
        try {
            ManCtl.start_cron();
        } catch (Exception e){
            system.assertEquals(system.label.already_initialized, e.getMessage());
        }
    }
}