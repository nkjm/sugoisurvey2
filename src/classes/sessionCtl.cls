public with sharing class sessionCtl extends html5tCtl {

    private class sexception extends exception {}

    @remoteAction
    public static config__c get_config(){
        return config__c.getOrgDefaults();
    }

    @remoteAction
    public static void register_guest(guest__c guest, list<custom_survey_answer__c> csas){
        Savepoint sp = Database.setSavepoint();
        guest = create_guest(guest);
        try {
            submit_survey(guest.session__c, csas, security.encrypt(guest.id), true);
        } catch (Exception e){
            Database.rollback(sp);
            throw e;
        }
    }

    public static guest__c create_guest(guest__c guest){
        if (guest.session__c == null){
            sexception se = new sexception();
            se.setMessage(system.label.required_parameter_is_missing);
            throw se;
        }

        if (!String.isBlank(guest.email__c)){
            if ([select id from guest__c where session__c = :guest.session__c and email__c = :guest.email__c].size() > 0){
                sexception se = new sexception();
                se.setMessage(system.label.already_registered);
                throw se;
            }
        }

        if (String.isBlank(guest.last_name__c)){
            guest.last_name__c = system.label.lastname_unknown;
        }

        scrud.screate(guest);
        return guest;
    }

    @remoteAction
    public static void save_guest_as_contact(id guest_id){
        if (guest_id == null){
            sexception se = new sexception();
            se.setMessage(system.label.required_parameter_is_missing);
            throw se;
        }

        string soql_flds = scrud.getAccessibleFieldsInCSV('sugoisurvey5__Guest__c');
        string soql = 'select ' + soql_flds + ' from guest__c where id = :guest_id';
        list<guest__c> gs = Database.query(soql);

        if (gs.size() == 0){
            sexception se = new sexception();
            se.setMessage(system.label.guest_not_found);
            throw se;
        }

        guest__c g = gs[0];

        if (g.contact__c != null){
            sexception se = new sexception();
            se.setMessage(system.label.contact_already_exist);
            throw se;
        }

        account new_a;
        contact new_c = new contact();

        // Identify the account and kink contact to the corresponding account record.
        // Do link if exactly 1 record is found.
        if (g.company__c != null){
            list<account> accts = [select id from account where name = :g.company__c];
            if (accts.size() == 0){
                // create new account
                new_a = new account(name = g.company__c);
                scrud.screate(new_a);
                new_c.accountId = new_a.id;
            } else if (accts.size() == 1){
                // link to this account
                new_c.accountId = accts[0].id;
            } else if (accts.size() > 1){
                // Do not create or link account since we cannot identify which is the correct account.
            }
        }

        new_c.lastname = g.last_name__c;
        new_c.firstname = g.first_name__c;
        new_c.title = g.title__c;
        new_c.email = g.email__c;
        new_c.phone = g.phone__c;

        scrud.screate(new_c);

        // Link the guest to the new contact
        g.contact__c = new_c.id;
        scrud.supdate(g);
    }

    @remoteAction
    public static list<custom_survey_answer__c> get_answers_by_guest(id guest_id){
        if (guest_id == null){
            sexception se = new sexception();
            se.setMessage(system.label.required_parameter_is_missing);
            throw se;
        }

        // Check FLS
        string soql_flds_csa = scrud.getAccessibleFieldsInCSV('sugoisurvey5__Custom_Survey_Answer__c');
        list<string> flds_cso = scrud.getAccessibleFields('sugoisurvey5__Custom_Survey_Option__c');
        string soql_flds_cso = '';
        for (string fld : flds_cso){
            soql_flds_cso += 'custom_survey_option__r.' + fld + ',';
        }
        soql_flds_cso = soql_flds_cso.removeEnd(',');
        string soql_flds = soql_flds_csa + ',' + soql_flds_cso;
        string soql = 'select ' + soql_flds + ' from custom_survey_answer__c where guest__c = :guest_id';
        return Database.query(soql);
    }

    @remoteAction
    public static list<guest__c> get_guests_by_condition(id session_id, string search_by, string search_value){
        list<guest__c> guests;

        if (session_id == null || String.isEmpty(search_by) || String.isEmpty(search_value)){
            sexception se = new sexception();
            se.setMessage(system.label.required_parameter_is_missing);
            throw se;
        }

        if (search_by == 'cso_id') {
            guests = get_guests_by_cso_id(session_id, Id.valueOf(search_value));
        } else if (search_by == 'guest_id') {
            guests = get_guests_by_guest_id(session_id, Id.valueOf(search_value));
        } else if (search_by == 'range'){
            guests = get_guests_by_range(session_id, search_value);
        } else {
            sexception se = new sexception();
            se.setMessage('Invalid value for search_by');
            throw se;
        }

        return guests;
    }

    private static list<guest__c> get_guests_by_cso_id(id session_id, id cso_id){
        list<guest__c> guests = new list<guest__c>();

        if (session_id == null || cso_id == null){
            sexception se = new sexception();
            se.setMessage(system.label.required_parameter_is_missing);
            throw se;
        }

        // Check FLS
        list<string> flds = scrud.getAccessibleFields('sugoisurvey5__Guest__c');

        // Dynamic SOQL
        string soql_flds = '';
        for (string fld : flds){
            soql_flds += 'guest__r.' + fld + ',';
        }
        soql_flds = soql_flds.removeEnd(',');
        string soql = 'select ' + soql_flds + ' from custom_survey_answer__c where session__c = :session_id and custom_survey_option__r.id = :cso_id order by guest__r.company__c';
        list<custom_survey_answer__c> csas = Database.query(soql);
        
        // Generate guests
        for (custom_survey_answer__c csa : csas){
            guests.add(csa.guest__r);
        }

        return guests;
    }

    private static list<guest__c> get_guests_by_guest_id(id session_id, id guest_id){
        list<guest__c> guests = new list<guest__c>();

        if (session_id == null || guest_id == null){
            sexception se = new sexception();
            se.setMessage(system.label.required_parameter_is_missing);
            throw se;
        }

        // Check FLS
        string soql_flds = scrud.getAccessibleFieldsInCSV('sugoisurvey5__Guest__c');
        string soql = 'select ' + soql_flds + ' from guest__c where session__c = :session_id and id = :guest_id';
        guests = Database.query(soql);

        return guests;
    }

    private static list<guest__c> get_guests_by_range(id session_id, string range){
        list<guest__c> guests = new list<guest__c>();

        if (session_id == null || range == null){
            sexception se = new sexception();
            se.setMessage(system.label.required_parameter_is_missing);
            throw se;
        }

        integer min = Integer.valueOf(range.split('-', 0)[0]);
        integer max = Integer.valueOf(range.split('-', 0)[1]);

        string soql = 'select id, guest__r.id from custom_survey_answer__c where session__c = :session_id and free_form_of_number__c >= :min and free_form_of_number__c <= :max';
        list<custom_survey_answer__c> csas = Database.query(soql);
        list<id> guest_ids = new list<id>();
        for (custom_survey_answer__c csa : csas){
            guest_ids.add(csa.guest__r.id);
        }

        // Check FLS
        string soql_flds = scrud.getAccessibleFieldsInCSV('sugoisurvey5__Guest__c');
        soql = 'select ' + soql_flds + ' from guest__c where session__c = :session_id and id in :guest_ids';
        guests = Database.query(soql);

        return guests;
    }


    @remoteAction
    public static list<custom_survey_answer__c> get_free_answers(id csq_id){
        if (csq_id == null){
            sexception se = new sexception();
            se.setMessage(system.label.required_parameter_is_missing);
            throw se;
        }
        
        string survey_type = [select survey_type__c from custom_survey_question__c where id = :csq_id].survey_type__c;
        
        string soql_flds = scrud.getAccessibleFieldsInCSV('sugoisurvey5__Custom_Survey_Answer__c');
        string soql;
        if (survey_type == 'checkbox' || survey_type == 'radio'){
            soql = 'select ' + soql_flds + ' from custom_survey_answer__c where custom_survey_option__r.custom_survey_question__c = :csq_id AND custom_survey_option__r.enable_free_form__c = true AND free_form__c != null order by createdDate desc';
        } else if (survey_type == 'free'){
            soql = 'select ' + soql_flds + ' from custom_survey_answer__c where custom_survey_option__r.custom_survey_question__c = :csq_id AND custom_survey_option__r.dummy__c = true AND free_form__c != null order by createdDate desc';
        } else if (survey_type == 'number'){
            soql = 'select ' + soql_flds + ' from custom_survey_answer__c where custom_survey_option__r.custom_survey_question__c = :csq_id AND custom_survey_option__r.dummy__c = true AND free_form_of_number__c != null order by createdDate desc';
        } else {
            return null;
        }
        
        return Database.query(soql);
    }

    @remoteAction
    public static void submit_survey(id session_id, list<custom_survey_answer__c> csas, string sguest_id, boolean for_registration){
        if (session_id == null){
            sexception se = new sexception();
            se.setMessage(system.label.session_id_is_not_set);
            throw se;
        }

        if (csas == null){
            sexception se = new sexception();
            se.setMessage(system.label.csas_is_not_set);
            throw se;
        }

        session__c session = (session__c)scrud.sread('sugoisurvey5__Session__c', session_id);

        map<id, custom_survey_answer__c> csas_map_by_option_id = new map<id, custom_survey_answer__c>();
        for (custom_survey_answer__c csa : csas){
            csas_map_by_option_id.put(csa.custom_survey_option__c, csa);
        }

        id guest_id;
        if (String.isNotBlank(sguest_id)){
            guest_id = security.decrypt(sguest_id);
        }

        ////
        //// Check required question and option
        ////

        // Retrieve questions which is flagged 'required' depending on for_registration or not.
        list<custom_survey_question__c> csqs_for_required_check;
        string soql_for_csqs_for_required_check = 'select id, question__c, survey_type__c, (select id, option__c, required__c from custom_survey_option__r) from custom_survey_question__c where session__c = :session_id and required__c = true and for_registration__c = ' + String.valueOf(for_registration) + ' order by sort_order__c';
        csqs_for_required_check = Database.query(soql_for_csqs_for_required_check);

        for (custom_survey_question__c csq : csqs_for_required_check){
            if (csq.survey_type__c == 'guest'){
                if (guest_id != null){
                    continue;
                }
                // For the survey type of guest.
                for (custom_survey_option__c cso : csq.custom_survey_option__r){
                    if (cso.required__c == true){
                        if (csas_map_by_option_id.get(cso.id) == null){
                            sexception se = new sexception();
                            se.setMessage(system.label.pls_enter_required_field + ' ' + csq.question__c);
                            throw se;  
                        }

                        if (string.isBlank(csas_map_by_option_id.get(cso.id).free_form__c)){
                            sexception se = new sexception();
                            se.setMessage(system.label.pls_enter_required_field + ' ' + csq.question__c);
                            throw se;  
                        }
                    }
                }
            } else {
                // For the survey type of other than guest.
                set<string> opt_ids = new set<string>();
                for (custom_survey_option__c opt : csq.custom_survey_option__r){
                    opt_ids.add(string.valueOf(opt.id));
                }
                boolean required_answer_found = false;
                for (custom_survey_answer__c csa : csas){
                    if (opt_ids.contains(csa.custom_survey_option__c)){
                        if (csq.survey_type__c == 'free'){
                            if (!string.isBlank(csa.free_form__c)){
                                required_answer_found = true;
                            }
                        } else if (csq.survey_type__c == 'number'){
                            if (csa.free_form_of_number__c != null){
                                required_answer_found = true;
                            }
                        } else {
                            required_answer_found = true;
                        }
                    }
                }
                if (!required_answer_found){
                    sexception se = new sexception();
                    se.setMessage(system.label.pls_enter_required_field + ' ' + csq.question__c);
                    throw se;
                }
            }
        }

        ////
        //// Check entitlement and identify guest
        ////
        guest__c guest;
        if (for_registration == false){
            if (guest_id != null){

                // sguest_id is specified so retrieve the guest record.
                string soql_flds = scrud.getAccessibleFieldsInCSV('sugoisurvey5__Guest__c');
                string soql = 'select ' + soql_flds + ' from guest__c where id = :guest_id and session__c = :session_id';
                list<guest__c> guests = Database.query(soql);
                if (guests.size() == 0){
                    sexception se = new sexception();
                    se.setMessage(system.label.guest_not_found);
                    throw se;
                }
                guest = guests[0];

            } else {

                guest = new guest__c();
                guest.session__c = session.id;

                custom_survey_question__c csq_for_guest;
                try {
                    csq_for_guest = [select id, (select id, option__c from custom_survey_option__r) from custom_survey_question__c where session__c = :session.id and survey_type__c = 'guest'];
                } catch (QueryException qe){
                    csq_for_guest = null;
                }

                if (csq_for_guest != null){
                    for (custom_survey_option__c cso_for_guest : csq_for_guest.custom_survey_option__r){
                        if (csas_map_by_option_id.get(cso_for_guest.id) != null && !String.isBlank(csas_map_by_option_id.get(cso_for_guest.id).free_form__c)){
                            guest.put(cso_for_guest.option__c, csas_map_by_option_id.get(cso_for_guest.id).free_form__c);
                        }
                    }
                }

                if (session.who_can_submit_survey__c == '無条件' || session.who_can_submit_survey__c == 'Anyone'){

                    if (string.isBlank(guest.email__c)){
                        // email has not been entered.
                        if (string.isBlank(guest.last_name__c)){
                            guest.last_name__c = system.label.unregistered_guest;
                        }
                        scrud.screate(guest);
                    } else if (identify_guest(session.id, guest.email__c) == null){
                        // guest does not exist so create new guest.
                        if (string.isBlank(guest.last_name__c)){
                            guest.last_name__c = system.label.unregistered_guest;
                        }
                        scrud.screate(guest);
                    } else {
                        // guest already exsits so udpate it with submitted values.
                        guest.id = identify_guest(session.id, guest.email__c).id;
                        scrud.supdate(guest);
                    }

                } else if (session.who_can_submit_survey__c == 'Eメールの入力が必要' || session.who_can_submit_survey__c == 'Require Email'){

                    if (string.isBlank(guest.email__c)){
                        // email has not been entered.
                        sexception se = new sexception();
                        se.setMessage(system.label.pls_input_email);
                        throw se;  
                    }

                    if (identify_guest(session.id, guest.email__c) == null){
                        // guest does not exist so create new guest.
                        if (string.isBlank(guest.last_name__c)){
                            guest.last_name__c = system.label.unregistered_guest;
                        }
                        scrud.screate(guest);
                    } else {
                        // guest already exsits so udpate it with submitted values.
                        guest.id = identify_guest(session.id, guest.email__c).id;
                        scrud.supdate(guest);
                    }

                } else if (session.who_can_submit_survey__c == '事前登録者のみ' || session.who_can_submit_survey__c == 'Registered Guests Only'){

                    if (string.isBlank(guest.email__c)){
                        // email has not been entered.
                        sexception se = new sexception();
                        se.setMessage(system.label.pls_input_email);
                        throw se;  
                    }

                    if (identify_guest(session.id, guest.email__c) == null){
                        // guest does not exist.
                        sexception se = new sexception();
                        se.setMessage(system.label.email_not_registered);
                        throw se;
                    }

                    // guest already exsits so udpate it with submitted values.
                    guest.id = identify_guest(session.id, guest.email__c).id;
                    scrud.supdate(guest);
                }
            }


            ////
            //// Check duplication
            ////
            guest = (guest__c)scrud.sread('sugoisurvey5__Guest__c', guest.id);
            if (guest.status__c == 'submitted'){
                sexception se = new sexception();
                se.setMessage(system.label.already_submitted);
                throw se;
            }
        }

        ////
        //// Insert CSA
        ////
        list<custom_survey_answer__c> csas_to_create = new list<custom_survey_answer__c>();
        for (custom_survey_answer__c csa : csas){
            if (csa.custom_survey_option__c == null){
                continue;
            }
            csa.session__c = session.id;
            if (guest_id == null){
                csa.guest__c = guest.id;
            } else {
                csa.guest__c = guest_id;
            }
            csas_to_create.add(csa);
        }
        scrud.screate(csas_to_create);


        ////
        //// Update Guest status to "submitted"
        ////
        if (for_registration == false){
            guest.status__c = 'submitted';
            scrud.supdate(guest);
        }

        ////
        //// Send mail if handout_send_on_submission__c is set
        ////
        if (for_registration == false){
            if (session.mail_handout_send_on_submission__c == true && !String.isEmpty(guest.email__c) && guest.handout_delivered__c == false){
                list<guest__c> guests = new list<guest__c>();
                guests.add(guest);
                send_mail(session.id, 'handout', session.mail_handout_to__c, session.mail_handout_subject__c, session.mail_handout_body_l__c, session.mail_handout_sender__c, guests);
            }
        }
    }

    private static guest__c identify_guest(id session_id, string guest_email){
        string soql_flds = scrud.getAccessibleFieldsInCSV('sugoisurvey5__Guest__c');
        string soql = 'select ' + soql_flds + ' from guest__c where session__c = :session_id and email__c = :guest_email';
        list<guest__c> guests = Database.query(soql);
        if (guests.size() != 1){
            return null;
        }
        return guests[0];
    }

    public static void create_csq_of_guest(id session_id){
        boolean question_for_guest_found = false;
        boolean option_for_email_found = false;
        custom_survey_question__c csq_for_guest;
        for (custom_survey_question__c csq : [select id, (select id, option__c from custom_survey_option__r where option__c = 'sugoisurvey5__Email__c') from custom_survey_question__c where session__c = :session_id and survey_type__c = 'guest']){
            csq_for_guest = csq;
            question_for_guest_found = true;
            if (csq.custom_survey_option__r.size() > 0){
                option_for_email_found = true;
            }
        }

        if (!question_for_guest_found){
            custom_survey_question__c csq = new custom_survey_question__c(
                question__c = system.label.pls_enter_guest_info,
                survey_type__c = 'guest',
                required__c = true,
                session__c = session_id
            );
            list<custom_survey_option__c> csos = new list<custom_survey_option__c>();
            csos.add(new custom_survey_option__c(
                option__c = 'sugoisurvey5__Email__c',
                required__c = true,
                session__c = session_id
            ));
            sessionCtl.create_question(csq, csos);
        }

        if (question_for_guest_found && !option_for_email_found){
            csq_for_guest.required__c = true;
            scrud.supdate(csq_for_guest);
            custom_survey_option__c cso = new custom_survey_option__c(
                option__c = 'sugoisurvey5__Email__c',
                required__c = true,
                session__c = session_id,
                custom_survey_question__c = csq_for_guest.id
            );
            scrud.screate(cso);
        }
    }

    @remoteAction
    public static session__c create_session(session__c session){
        if (String.isEmpty(session.name)){
            sexception se = new sexception();
            se.setMessage(system.label.pls_enter_session_name);
            throw se;
        }

        scrud.screate(session);
        session.secure_id__c = security.encrypt(session.id);
        scrud.supdate(session);
        session = (session__c)scrud.sread('sugoisurvey5__Session__c', session.id);

        // Create CSQ asking guest information
        if (session.who_can_submit_survey__c == 'Registered Guests Only' ||
            session.who_can_submit_survey__c == '事前登録者のみ' || 
            session.who_can_submit_survey__c == 'Require Email' ||
            session.who_can_submit_survey__c == 'Eメールの入力が必要'){

            create_csq_of_guest(session.id);
        }

        return session;
    }

    @remoteAction
    public static session__c update_session(session__c session){
        if (session.date__c == null){
            session.date__c = null;
        }

        scrud.supdate(session);
        session = (session__c)scrud.sread('sugoisurvey5__Session__c', session.id);

        // Create CSQ asking guest information
        if (session.who_can_submit_survey__c == 'Registered Guests Only' ||
            session.who_can_submit_survey__c == '事前登録者のみ' || 
            session.who_can_submit_survey__c == 'Require Email' ||
            session.who_can_submit_survey__c == 'Eメールの入力が必要'){

            create_csq_of_guest(session.id);
        }

        return session;
    }
    
    @remoteAction
    public static session__c get_session(id session_id){
        session__c session;
        
        if (session_id == null){
            sexception se = new sexception();
            se.setMessage(system.label.session_id_is_not_set);
            throw se;
        }

        list<guest__c> guests = [select id from guest__c where session__c = :session_id AND secure_id__c = null];
        if (guests.size() > 0){
            for (guest__c g : guests){
                g.secure_id__c = security.encrypt(g.id);
            }
            scrud.supdate(guests);
        }

        string soql_session_flds = scrud.getAccessibleFieldsInCSV('sugoisurvey5__Session__c');
        string soql_csq_flds = '(select ' + scrud.getAccessibleFieldsInCSV('sugoisurvey5__Custom_Survey_Question__c') + ' from custom_survey_question__r order by sort_order__c, createdDate)';
        string soql_cso_flds = '(select ' + scrud.getAccessibleFieldsInCSV('sugoisurvey5__Custom_Survey_Option__c') + ' from custom_survey_option__r order by enable_free_form__c, Name)';
        string soql_guest_flds = '(select ' + scrud.getAccessibleFieldsInCSV('sugoisurvey5__Guest__c') + ' from guest__r order by name)';
        string soql_presenter_flds = '';
        list<string> presenter_flds = scrud.getAccessibleFields('sugoisurvey5__Presenter__c');
        for (string presenter_fld : presenter_flds){
            soql_presenter_flds += 'presenter__r.' + presenter_fld + ',';
        }
        soql_presenter_flds = soql_presenter_flds.removeEnd(',');

        string soql_flds = soql_session_flds + ',' + soql_csq_flds + ',' + soql_cso_flds + ',' + soql_guest_flds + ',' + soql_presenter_flds;
        string soql = 'select ' + soql_flds + ' from session__c where id = :session_id';
        session = Database.query(soql);

        if (session.secure_id__c == null){
            session.secure_id__c = security.encrypt(session.id);
            scrud.supdate(session);
        }

        return session;
    }

    // FOR BACKWARD COMPATIBILITY. Should be removed by Oct 2014.
    @remoteAction
    public static session__c deprecated_get_session_for_sites(string session_id, string condition){
        return get_session_for_sites(security.encrypt(session_id), condition);
    }

    @remoteAction
    public static session__c get_session_for_sites(string secure_session_id, string condition){
        if (String.isBlank(secure_session_id)){
            sexception se = new sexception();
            se.setMessage(system.label.session_id_is_not_set);
            throw se;
        }

        string session_id = security.decrypt(secure_session_id);

        // Check if Condition is correct.
        if (condition != 'survey_opening' && condition != 'registration_opening'){
            sexception se = new sexception();
            se.setMessage(system.label.request_invalid);
            throw se;
        }
        
        string soql_session_flds = scrud.getAccessibleFieldsInCSV('sugoisurvey5__Session__c');
        string soql_csq_flds;
        if (condition == 'survey_opening'){
            soql_csq_flds = '(select ' + scrud.getAccessibleFieldsInCSV('sugoisurvey5__Custom_Survey_Question__c') + ' from custom_survey_question__r where for_registration__c = false order by sort_order__c, createdDate)';
        } else if (condition == 'registration_opening'){
            soql_csq_flds = '(select ' + scrud.getAccessibleFieldsInCSV('sugoisurvey5__Custom_Survey_Question__c') + ' from custom_survey_question__r where for_registration__c = true order by sort_order__c, createdDate)';
        }
        string soql_cso_flds = '(select ' + scrud.getAccessibleFieldsInCSV('sugoisurvey5__Custom_Survey_Option__c') + ' from custom_survey_option__r order by enable_free_form__c, Name)';
        string soql_flds = soql_session_flds + ',' + soql_csq_flds + ',' + soql_cso_flds;
        string soql = 'select ' + soql_flds + ' from session__c where id = :session_id';
        list<session__c> sessions = Database.query(soql);

        // Check if Session exist.
        if (sessions.size() == 0){
            sexception se = new sexception();
            se.setMessage(system.label.session_not_found);
            throw se;
        }

        // Check if Survey is opening.
        if (condition == 'survey_opening' && !sessions[0].open__c){
            sexception se = new sexception();
            se.setMessage(system.label.survey_is_over);
            throw se;
        }

        // Check if Guest registration is opening.
        if (condition == 'registration_opening' && !sessions[0].open_registration__c){
            sexception se = new sexception();
            se.setMessage(system.label.registration_is_over);
            throw se;
        }

        return sessions[0];
    }

    @remoteAction
    public static list<session__c> get_open_sessions_for_sites(){
        list<string> flds = new list<string>{'Name', 'sugoisurvey5__Date__c', 'sugoisurvey5__Secure_Id__c'};
        scrud.requireAccessible('sugoisurvey5__Session__c', flds);
        string soql_flds = '';
        for (string fld : flds){
            soql_flds += fld + ',';
        }
        soql_flds = soql_flds.removeEnd(',');
        string soql = 'select ' + soql_flds + ' from session__c where open__c = true order by date__c desc, name, createdDate';
        list<session__c> sessions = Database.query(soql);

        for (session__c s : sessions){
            if (s.secure_id__c == null){
                s.secure_id__c = security.encrypt(s.id);
            }
        }
        return sessions;
    }

    @remoteAction
    public static id clone_session(id session_id){
        if (session_id == null){
            sexception se = new sexception();
            se.setMessage(system.label.session_id_is_not_set);
            throw se;
        }
        
        // clone session record
        string session_fields = scrud.getCreateableFieldsInCSV('sugoisurvey5__Session__c');
        string csq_fields = '(select ' + scrud.getCreateableFieldsInCSV('sugoisurvey5__Custom_Survey_Question__c') + ' from custom_survey_question__r order by sort_order__c, name)';
        string cso_fields = '(select ' + scrud.getCreateableFieldsInCSV('sugoisurvey5__Custom_Survey_Option__c') + ' from custom_survey_option__r order by name)';

        string soql_fields = session_fields + ',' + csq_fields + ',' + cso_fields + ',' + '(select id, name from attachments)';
        string soql = 'select ' + soql_fields + ' from session__c where id = :session_id';
        session__c old_session = Database.query(soql);
        old_session.date__c = null;
        old_session.secure_id__c = null;

        session__c new_session = old_session.clone(false, true, false, false);
        new_session.name = new_session.name + ' - COPY';
        scrud.screate(new_session);
        
        // retrieve question records and clone
        list<custom_survey_question__c> old_csqs = old_session.custom_survey_question__r;
        list<custom_survey_question__c> new_csqs = old_csqs.deepclone();
        for (custom_survey_question__c new_csq : new_csqs){
            new_csq.session__c = new_session.id;
        }
        scrud.screate(new_csqs);
        
        // create map between old question id and new question id
        map<string, string> csq_id_map = new map<string, string>();
        integer i = 0;
        for (custom_survey_question__c old_csq : old_csqs){
            csq_id_map.put(old_csq.id, new_csqs[i].id);
            i++;
        }
        
        // retrieve option records and clone
        list<custom_survey_option__c> old_csos = old_session.custom_survey_option__r;
        list<custom_survey_option__c> new_csos = old_csos.deepclone();
        for (custom_survey_option__c new_cso : new_csos){
            new_cso.session__c = new_session.id;
            new_cso.custom_survey_question__c = csq_id_map.get(new_cso.custom_survey_question__c);
        }
        scrud.screate(new_csos);
        
        // retrieve Brand Logo and clone
        if (new_session.Brand_Logo_Id__c != null){
            id old_brand_logo_id = new_session.Brand_Logo_Id__c;
            Attachment old_attachment_for_brand_logo = [select Id, Name, Body, ParentId from Attachment where Id = :old_brand_logo_id];
            Attachment new_attachment_for_brand_logo = new Attachment(Name = old_attachment_for_brand_logo.Name, Body = old_attachment_for_brand_logo.Body, ParentId = new_session.Id);
            scrud.screate(new_attachment_for_brand_logo);
            new_session.Brand_Logo_Id__c = new_attachment_for_brand_logo.Id;
            scrud.supdate(new_session);
        }
        
        return new_session.Id;
    }

    @remoteAction
    public static id create_question(custom_survey_question__c csq, list<custom_survey_option__c> csos){
        // Check if session id is set
        if (csq.session__c == null){
            sexception e = new sexception();
            e.setMessage(system.label.session_id_is_not_set);
            throw e;
        }

        // Check if session exists
        try {
            string session_id_for_test = [select id from session__c where id = :csq.session__c].id;
        } catch (Exception e){
            sexception se = new sexception();
            se.setMessage(system.label.specified_session_does_not_exist);
            throw se;
        }
        
        // Check if question is set
        if (csq.question__c == null || csq.question__c == '') {
            sexception se = new sexception();
            se.setMessage(system.label.pls_enter_question);
            throw se;
        }

        
        ////
        //// add sort order if it has been set in existing questions
        ////
        list<custom_survey_question__c> existing_csqs;
        integer sort_order;

        // check FLS
        scrud.requireAccessible('sugoisurvey5__Custom_Survey_Question__c', new list<string>{'sugoisurvey5__Sort_Order__c'});

        existing_csqs = [select sort_order__c from custom_survey_question__c where session__c = :csq.session__c and sort_order__c != null order by sort_order__c desc];
        if(existing_csqs.size() > 0){
            csq.sort_order__c = existing_csqs[0].sort_order__c + 1;
        }


        ////
        //// Dispatch operation based on survey type
        ////
        id csq_id;
        if (csq.survey_type__c == 'checkbox' || csq.survey_type__c == 'radio'){
            csq_id = create_question_of_choice(csq, csos);
        } else if (csq.survey_type__c == 'free'){
            csq_id = create_question_of_free(csq);
        } else if (csq.survey_type__c == 'rating'){
            csq_id = create_question_of_rating(csq);
        } else if (csq.survey_type__c == 'number'){
            csq_id = create_question_of_number(csq);
        } else if (csq.survey_type__c == 'guest'){
            csq_id = create_question_of_guest(csq, csos);
        }

        return csq_id;
    }

    private static id create_question_of_choice(custom_survey_question__c csq, list<custom_survey_option__c> csos){
        scrud.screate(csq);

        list<custom_survey_option__c> csos_to_add = new list<custom_survey_option__c>();
        for (custom_survey_option__c cso : csos){
            if (!string.isBlank(cso.option__c)){
                csos_to_add.add(new custom_survey_option__c(
                    session__c = csq.session__c,
                    custom_survey_question__c = csq.id,
                    option__c = cso.option__c
                ));
            }
        }

        if (csq.enable_free_form__c){
            // add option for free form
            csos_to_add.add(new custom_survey_option__c(
                session__c = csq.session__c,
                custom_survey_question__c = csq.id,
                option__c = system.label.other,
                enable_free_form__c = true
            ));
        }

        scrud.screate(csos_to_add);
        return csq.id;
    }

    private static id create_question_of_free(custom_survey_question__c csq){
        scrud.screate(csq);

        list<custom_survey_option__c> csos_to_add = new list<custom_survey_option__c>();
        csos_to_add.add(new custom_survey_option__c(
            session__c = csq.session__c,
            custom_survey_question__c = csq.id,
            option__c = system.label.dummy,
            dummy__c = true
        ));

        scrud.screate(csos_to_add);
        return csq.id;
    }

    private static id create_question_of_rating(custom_survey_question__c csq){
        if (!(csq.rating_steps__c >= 1 && csq.rating_steps__c <= 10)){
            sexception se = new sexception();
            se.setMessage(system.label.rating_steps_is_invalid);
            throw se;
        }

        scrud.screate(csq);

        list<custom_survey_option__c> csos_to_add = new list<custom_survey_option__c>();
        while (csos_to_add.size() < csq.rating_steps__c){
            csos_to_add.add(new custom_survey_option__c(
                session__c = csq.session__c,
                custom_survey_question__c = csq.id,
                option_of_number__c = csos_to_add.size() + 1
            ));
        }

        scrud.screate(csos_to_add);
        return csq.id;
    }

    private static id create_question_of_number(custom_survey_question__c csq){
        scrud.screate(csq);

        list<custom_survey_option__c> csos_to_add = new list<custom_survey_option__c>();
        csos_to_add.add(new custom_survey_option__c(
            session__c = csq.session__c,
            custom_survey_question__c = csq.id,
            option__c = system.label.dummy,
            dummy__c = true
        ));

        scrud.screate(csos_to_add);
        return csq.id;
    }

    private static id create_question_of_guest(custom_survey_question__c csq, list<custom_survey_option__c> csos){
        if ([select id from custom_survey_question__c where session__c = :csq.session__c and survey_type__c = 'guest'].size() > 0){
            sexception se = new sexception();
            se.setMessage(system.label.guest_question_already_exists);
            throw se;
        }

        scrud.screate(csq);

        list<custom_survey_option__c> csos_to_add = new list<custom_survey_option__c>();
        boolean required_option_found = false;
        for (custom_survey_option__c cso : csos){
            if (!string.isBlank(cso.option__c)){
                csos_to_add.add(new custom_survey_option__c(
                    session__c = csq.session__c,
                    custom_survey_question__c = csq.id,
                    option__c = cso.option__c,
                    required__c = cso.required__c
                ));
                if (cso.required__c){
                    required_option_found = true;
                }
            }
        }
        scrud.screate(csos_to_add);

        if (required_option_found){
            csq.required__c = true;
            scrud.supdate(csq);
        }
        return csq.id;
    }


    @remoteAction
    public static void update_question(custom_survey_question__c new_csq, list<custom_survey_option__c> new_csos){
        // Check if csq.session__c is not empty.
        if (new_csq.session__c == null){
            sexception se = new sexception();
            se.setMessage(system.label.session_id_is_not_set);
            throw se;
        }
        
        // Check if custom_survey_question__c.id is not empty.
        if (new_csq.id == null){
            sexception se = new sexception();
            se.setMessage(system.label.survey_id_is_not_set);
            throw se;
        }
        
        // Check if custom_survey_question__c.question__c is not empty.
        if (new_csq.question__c == null || new_csq.question__c == ''){
            sexception se = new sexception();
            se.setMessage(system.label.pls_enter_question);
            throw se;
        }

        // Check if session exists.
        try {
            string session_id_for_test = [select id from session__c where id = :new_csq.session__c].id;
        } catch (Exception e){
            sexception se = new sexception();
            se.setMessage(system.label.specified_session_does_not_exist);
            throw se;
        }

        
        ////
        //// Retrieve existing csq
        ////

        // define fields
        list<string> csq_flds = new list<string>{'Id','sugoisurvey5__Question__c','sugoisurvey5__Survey_Type__c','sugoisurvey5__Required__c','sugoisurvey5__Enable_Free_Form__c','sugoisurvey5__Session__c','sugoisurvey5__Rating_Steps__c'};
        // check FLS
        scrud.requireAccessible('sugoisurvey5__Custom_Survey_Question__c', csq_flds);
        // dynamic SOQL
        string soql_flds = '';
        for (string csq_fld : csq_flds){
            soql_flds += csq_fld + ',';
        }
        soql_flds = soql_flds.removeEnd(',');
        id csq_id = new_csq.id;
        id session_id = new_csq.session__c;
        string soql = 'select ' + soql_flds + ' from custom_survey_question__c where id = :csq_id AND session__c = :session_id';
        custom_survey_question__c old_csq;
        try {
            old_csq = Database.query(soql);
        } catch (Exception e){
            sexception se = new sexception();
            se.setMessage(system.label.specified_question_not_found);
            throw se;
        }


        ////
        //// Retrieve existing csos
        ////

        // define fields
        list<string> cso_flds = new list<string>{'Id','sugoisurvey5__Option__c','sugoisurvey5__Option_Of_Number__c','sugoisurvey5__Custom_Survey_Question__c','sugoisurvey5__Enable_Free_Form__c','sugoisurvey5__Dummy__c','sugoisurvey5__Session__c','sugoisurvey5__Required__c'};
        // check FLS
        scrud.requireAccessible('sugoisurvey5__Custom_Survey_Option__c', cso_flds);
        // dynamic SOQL
        soql_flds = '';
        for (string cso_fld : cso_flds){
            soql_flds += cso_fld + ',';
        }
        soql_flds = soql_flds.removeEnd(',');
        soql = 'select ' + soql_flds + ' from custom_survey_option__c where custom_survey_question__c = :csq_id';
        list<custom_survey_option__c> old_csos = Database.query(soql);


        ////
        //// Dispatch operation based on survey type
        ////
        if (old_csq.survey_type__c == 'checkbox' || old_csq.survey_type__c == 'radio'){
            update_question_of_choice(old_csq, new_csq, old_csos, new_csos);
        } else if (old_csq.survey_type__c == 'free'){
            update_question_of_free(new_csq);
        } else if (old_csq.survey_type__c == 'rating'){
            update_question_of_rating(old_csq, new_csq);
        } else if (old_csq.survey_type__c == 'number'){
            update_question_of_number(new_csq);
        } else if (old_csq.survey_type__c == 'guest'){
            update_question_of_guest(new_csq, new_csos);
        }
    }

    private static void update_question_of_choice(custom_survey_question__c old_csq, custom_survey_question__c new_csq, list<custom_survey_option__c> old_csos, list<custom_survey_option__c> new_csos){
        scrud.supdate(new_csq);

        // Check if enable_free_form should be enabled/disabled.
        string action_for_other = 'stay';
        if (old_csq.enable_free_form__c == false && new_csq.enable_free_form__c == true){
            action_for_other = 'enable';
        } else if (old_csq.enable_free_form__c == true && new_csq.enable_free_form__c == false){
            action_for_other = 'disable';
        }

        // Create new options and update options.
        list<string> upsert_fields = new list<string>{'sugoisurvey5__Option__c','sugoisurvey5__Custom_Survey_Question__c','sugoisurvey5__Enable_Free_Form__c','sugoisurvey5__Dummy__c','sugoisurvey5__Session__c'};
        scrud.requireCreateable('sugoisurvey5__Custom_Survey_Option__c', upsert_fields);
        scrud.requireUpdateable('sugoisurvey5__Custom_Survey_Option__c', upsert_fields);

        // Set missing required fields
        for (custom_survey_option__c cso : new_csos){
            cso.session__c = old_csq.session__c;
            cso.custom_survey_question__c = old_csq.id;
        }

        upsert new_csos;
        
        // add option for Other
        if (action_for_other == 'enable'){
            insert new custom_survey_option__c(
                session__c = old_csq.session__c,
                custom_survey_question__c = old_csq.id,
                option__c = system.label.other,
                enable_free_form__c = true
            );
        }
    
        // Prepare options to be deleted.
        list<custom_survey_option__c> csos_to_delete = new list<custom_survey_option__c>();
        boolean found = false;
        for (custom_survey_option__c cso_tmp : old_csos){
            for (custom_survey_option__c cso_to_delete : new_csos){
                if (cso_to_delete.id == cso_tmp.id){
                    found = true;
                    if (cso_to_delete.option__c == null || cso_to_delete.option__c == ''){
                        csos_to_delete.add(cso_tmp);
                    }
                }
            }
            if (found == false && cso_tmp.enable_free_form__c == false && cso_tmp.dummy__c == false){
                csos_to_delete.add(cso_tmp);
            }
            found = false;
        }
        
        // delete options
        scrud.sdelete(csos_to_delete);

        // delete option for Other
        if (action_for_other == 'disable'){
            scrud.sdelete([select id from custom_survey_option__c where session__c = :old_csq.session__c AND custom_survey_question__c = :old_csq.id AND enable_free_form__c = true]);
        }
    }

    private static void update_question_of_free(custom_survey_question__c new_csq){
        scrud.supdate(new_csq);
    }

    private static void update_question_of_rating(custom_survey_question__c old_csq, custom_survey_question__c new_csq){
        if (!(new_csq.rating_steps__c >= 1 && new_csq.rating_steps__c <= 10)){
            sexception se = new sexception();
            se.setMessage(system.label.rating_steps_is_invalid);
            throw se;
        }

        scrud.supdate(new_csq);

        //// add options
        if (new_csq.rating_steps__c > old_csq.rating_steps__c){
            list<custom_survey_option__c> csos_to_add = new list<custom_survey_option__c>();
            while (csos_to_add.size() < (new_csq.rating_steps__c - old_csq.rating_steps__c)){
                csos_to_add.add(new custom_survey_option__c(
                    session__c = new_csq.session__c,
                    custom_survey_question__c = new_csq.id,
                    option_of_number__c = old_csq.rating_steps__c + csos_to_add.size() + 1
                ));
            }
            scrud.screate(csos_to_add);
        }

        //// delete options
        if (new_csq.rating_steps__c < old_csq.rating_steps__c){
            scrud.sdelete([select id from custom_survey_option__c where session__c = :old_csq.session__c AND custom_survey_question__c = :old_csq.id AND option_of_number__c > :new_csq.rating_steps__c]);
        }
    }

    private static void update_question_of_number(custom_survey_question__c new_csq){
        scrud.supdate(new_csq);
    }

    private static void update_question_of_guest(custom_survey_question__c new_csq, list<custom_survey_option__c> new_csos){
        scrud.supdate(new_csq);

        scrud.sdelete([select id from custom_survey_option__c where session__c = :new_csq.session__c AND custom_survey_question__c = :new_csq.id]);
        list<custom_survey_option__c> csos_to_add = new list<custom_survey_option__c>();
        boolean required_option_found = false;
        for (custom_survey_option__c cso : new_csos){
            if (cso.option__c != null && cso.option__c != ''){
                csos_to_add.add(new custom_survey_option__c(
                    session__c = new_csq.session__c,
                    custom_survey_question__c = new_csq.id,
                    option__c = cso.option__c,
                    required__c = cso.required__c
                ));
                if (cso.required__c){
                    required_option_found = true;
                }
            }
        }
        scrud.screate(csos_to_add);

        if (required_option_found){
            new_csq.required__c = true;
            scrud.supdate(new_csq);
        }
    }

    @remoteAction
    public static void sort_questions(id session_id, list<id> question_ids){
        if (session_id == null){
            sexception se = new sexception();
            se.setMessage(system.label.session_id_is_not_set);
            throw se;
        }
        
        if (question_ids.size() < 2){
            sexception se = new sexception();
            se.setMessage(system.label.there_are_not_enough_number_of_question_to_sort);
            throw se;
        }
        
        // check FLS
        list<string> csq_flds = new list<string>{'Id','sugoisurvey5__Sort_Order__c'};
        scrud.requireAccessible('sugoisurvey5__Custom_Survey_Question__c', csq_flds);

        list<custom_survey_question__c> csqs = [select id, sort_order__c from custom_survey_question__c where session__c = :session_id];

        if (csqs.size() < 2){
            sexception se = new sexception();
            se.setMessage(system.label.there_are_not_enough_number_of_question_to_sort);
            throw se;
        }
        
        if (csqs.size() != question_ids.size()){
            sexception se = new sexception();
            se.setMessage(system.label.requested_number_of_question_is_not_valid);
            throw se;
        }
        
        integer sort_order = 1;
        boolean found = false;
        for (id question_id : question_ids){
            for (custom_survey_question__c csq : csqs){
                if (csq.id == question_id){
                    csq.sort_order__c = sort_order;
                    found = true;
                    break;
                }
            }
            if (found == false){
                sexception se = new sexception();
                se.setMessage(system.label.specified_question_not_found);
                throw se;
            }
            sort_order++;
            found = false;
        }
        
        scrud.supdate(csqs);
    }

    @remoteAction
    public static list<guest__c> get_guests_to_be_delivered(id session_id, string template, string to){
        list<guest__c> guests = new list<guest__c>();
        
        if (session_id == null || String.isEmpty(template) || String.isEmpty(to)){
            sexception se = new sexception();
            se.setMessage(system.label.required_parameter_is_missing);
            throw se;
        }
        
        string soql_flds = scrud.getAccessibleFieldsInCSV('sugoisurvey5__Guest__c');
        string soql = 'select ' + soql_flds + ' from guest__c where session__c = :session_id and email__c <> null and email__c <> \'\'';
        for (guest__c g : Database.query(soql)){
            if (template == 'free'){
                if (to == 'anyone'){
                    if (g.mail_delivered__c == false){
                        guests.add(g);
                    }
                } else if (to == 'attendees'){
                    if (g.mail_delivered__c == false && g.checkin__c == true){
                        guests.add(g);
                    }
                } else if (to == 'who_have_submitted_survey'){
                    if (g.mail_delivered__c == false && g.status__c == 'submitted'){
                        guests.add(g);
                    }
                }
            } else if (template == 'guest_pass'){
                if (to == 'anyone'){
                    if (g.guest_pass_delivered__c == false){
                        guests.add(g);
                    }
                } else if (to == 'attendees'){
                    if (g.guest_pass_delivered__c == false && g.checkin__c == true){
                        guests.add(g);
                    }
                } else if (to == 'who_have_submitted_survey'){
                    if (g.guest_pass_delivered__c == false && g.status__c == 'submitted'){
                        guests.add(g);
                    }
                }
            } else if (template == 'survey_link'){
                if (to == 'anyone'){
                    if (g.survey_link_delivered__c == false){
                        guests.add(g);
                    }
                } else if (to == 'attendees'){
                    if (g.survey_link_delivered__c == false && g.checkin__c == true){
                        guests.add(g);
                    }
                } else if (to == 'who_have_submitted_survey'){
                    if (g.survey_link_delivered__c == false && g.status__c == 'submitted'){
                        guests.add(g);
                    }
                }
            } else if (template == 'handout'){
                if (to == 'anyone'){
                    if (g.handout_delivered__c == false){
                        guests.add(g);
                    }
                } else if (to == 'attendees'){
                    if (g.handout_delivered__c == false && g.checkin__c == true){
                        guests.add(g);
                    }
                } else if (to == 'who_have_submitted_survey'){
                    if (g.handout_delivered__c == false && g.status__c == 'submitted'){
                        guests.add(g);
                    }
                }
            }
        }
        return guests;
    }

    @remoteAction
    public static integer send_mail(id session_id, string template, string to, string subject, string body, string sender, list<guest__c> guests){
        session__c session;
        
        // Check for session id
        if (session_id == null){
            sexception se = new sexception();
            se.setMessage(system.label.session_id_is_not_set);
            throw se;
        }

        // Define fields
        list<string> session_flds = new list<string>{'Id','Name','Date__c','Secure_Id__c'};

        // Check FLS
        scrud.requireAccessible('sugoisurvey5__Session__c', session_flds);

        // Dynamic SOQL
        string soql_session_flds = '';
        for (string session_fld : session_flds){
            soql_session_flds += session_fld + ',';
        }
        soql_session_flds = soql_session_flds.removeEnd(',');
        string soql_flds = soql_session_flds + ',' + '(select id, name from attachments)';
        string soql = 'select ' + soql_flds + ' from session__c where id = :session_id';
        session = Database.query(soql);
        
        // Check for template value
        if (String.isEmpty(template)){
            sexception se = new sexception();
            se.setMessage(system.label.required_parameter_is_missing + ' : template');
            throw se;
        }
        set<string> templates = new set<string>{'free', 'guest_pass', 'survey_link', 'handout'};
        if (!templates.contains(template)){
            sexception se = new sexception();
            se.setMessage(system.label.invalid_value + ' : ' + template + ' for template');
            throw se;
        }
        
        // Check for to value
        if (String.isEmpty(to)){
            sexception se = new sexception();
            se.setMessage(system.label.required_parameter_is_missing + ' : to');
            throw se;
        }
        set<string> tos = new set<string>{'anyone', 'attendees', 'who_have_submitted_survey'};
        if (!tos.contains(to)){
            sexception se = new sexception();
            se.setMessage(system.label.invalid_value + ' : ' + to + ' for to');
            throw se;
        }

        // retrive guest list to be delivered
        if (guests == null){
            guests = get_guests_to_be_delivered(session.id, template, to);
        }
        
        // retrieve attachment:
        List<Messaging.emailFileAttachment> efas = new List<Messaging.emailFileAttachment>();
        /*
        for (attachment a : session.attachments){
            attachment aa = [select name, contenttype, body from attachment where id = :a.id];
            Messaging.emailFileAttachment efa = new Messaging.emailFileAttachment();
            efa.setBody(aa.body);
            efa.setContentType(aa.contenttype);
            efa.setFileName(aa.name);
            efa.setInline(false);
            efas.add(efa);
        }
        */
           
        // reserve mail resource.
        Messaging.reserveSingleEmailCapacity(guests.size());
        
        List<Messaging.singleEmailMessage> mails = new List<Messaging.singleEmailMessage>();
        for (guest__c g : guests){
            
            //Initialize Messaging Object.
            Messaging.singleEmailMessage mail = new Messaging.singleEmailMessage();
                
            //Set To:
            list<string> to_addresses = new list<string>();
            to_addresses.add(g.email__c);
            mail.setToAddresses(to_addresses);
                
            //Set Sender:
            mail.setSenderDisplayName(sender);
                
            //Set Reply-To:
            mail.setReplyTo(sender);
            
            //Set Subject:
            subject = String.isEmpty(subject) ? '' : subject;
            mail.setSubject(subject);
            
            //Set Message Body:
            if (template == 'free'){
                mail.setPlainTextBody(body);
            } else if (template == 'guest_pass'){
                string g_date = session.date__c == null ? '' : session.date__c.format();
                string g_name = g.name__c == null ? '' : g.name__c;
                string g_company = g.company__c == null ? '' : g.company__c;
                body = '<div style="text-align:center;"><img src="https://chart.googleapis.com/chart?cht=qr&chs=150x150&chl=' + g.id + '"></img></div><div>' + system.label.event + ': ' + session.name + '</div><div>' + system.label.event_date + ': ' + g_date + '</div><div>' + system.label.your_company + ': ' + g_company + '</div><div>' + system.label.your_name + ': ' + g_name + '</div>';
                mail.setHtmlBody(body);
            } else if (template == 'survey_link'){
                config__c config = config__c.getOrgDefaults();
                string sguest_id = EncodingUtil.urlEncode(security.encrypt(g.id), 'UTF-8');
                string ssession_id = EncodingUtil.urlEncode(session.secure_id__c, 'UTF-8');
                body = '<p>' + system.label.survey + ' : ' + session.name + '</p><a href="' + config.survey_sites_url__c + '?ssession_id=' + ssession_id + '&sguest_id=' + sguest_id + '">' + config.survey_sites_url__c + '?ssession_id=' + ssession_id + '&sguest_id=' + sguest_id + '</a>';
                mail.setHtmlBody(body);
            } else if (template == 'handout'){
                body = String.isEmpty(body) ? '' : body;
                mail.setPlainTextBody(body);
            }
                
            //Set Attachment:
            if (efas.size() >= 1){
                mail.setFileAttachments(efas);
            }
                
            //Add to list
            mails.add(mail);
        }
                
        if (mails.size() > 0){
            // send
            Messaging.SendEmailResult[] sers = Messaging.sendEmail(mails);
            for (Messaging.SendEmailResult ser : sers){
                if (!ser.isSuccess()){
                    sexception se = new sexception();
                    Messaging.SendEmailError[] sees = ser.getErrors();
                    for (Messaging.SendEmailError see : sees){
                        se.setMessage(see.getMessage() + ' ');
                    }
                    throw se;
                }
            }
            
            // mark guest as delivered
            for (guest__c g : guests){
                if (template == 'free'){
                    g.mail_delivered__c = true;
                } else if (template == 'guest_pass'){
                    g.guest_pass_delivered__c = true;
                } else if (template == 'survey_link'){
                    g.survey_link_delivered__c = true;
                } else if (template == 'handout'){
                    g.handout_delivered__c = true;
                }
            }
            scrud.supdate(guests);
        }
        
        return mails.size();
    }

    @remoteAction 
    public static void clear_delivered_flag(id session_id, string template){
        list<guest__c> guests;
        
        if (session_id == null){
            sexception se = new sexception();
            se.setMessage(system.label.session_id_is_not_set);
            throw se;
        }
        
        // retrieve all guest related to the session
        guests = [select id from guest__c where session__c = :session_id];
        
        if (guests.size() == 0){
            return;
        }
        
        for (guest__c g : guests){
            if (template == 'free'){
                g.mail_delivered__c = false;
            } else if (template == 'guest_pass'){
                g.guest_pass_delivered__c = false;
            } else if (template == 'survey_link'){
                g.survey_link_delivered__c = false;
            } else if (template == 'handout'){
                g.handout_delivered__c = false;
            } else {
                sexception se = new sexception();
                se.setMessage(system.label.invalid_value + ' : ' + template + ' for template');
                throw se;
            }
        }
        scrud.supdate(guests);
    }
}