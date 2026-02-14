@IsTest
public class PaymentGWControllerTest {

    @testSetup static void setup() {
       MID_Config_for_Other_Charges__mdt bankConfig =  MID_Config_for_Other_Charges__mdt.getInstance('adcb_760076308333_aed');

    }
    
    @isTest
    static void callMethods() {

        Test.startTest();
        
        Account acc = TestObjectsFactory.getPersonAccountRecord(101, 'United Arab Emirates', 'V1', 'P1');
        acc.BillingStreet = '26/40 HAJI HUSSAIN STREET, KOTTAKUPPAM VILLAUPURAM DT.TAMIL Nadu India -440024';
        insert acc;

        Opportunity opp = TestObjectsFactory.getOpportunityRecord(acc.Id);
        insert opp;

        Project__c p= TestObjectsFactory.getProjectRecord('25083');
        insert p;
        
     
    
    
        Unit__c u = TestObjectsFactory.unitDataSetup(p.Id);        
        insert u;
        SalesOrder__c sa = TestObjectsFactory.getSalesOrderRecord(opp.Id,acc.Id);
        sa.Unit__c = u.Id;
        insert sa;

        OpportunityEOI__c eoi = TestObjectsFactory.getOpportunityEOIRecord(opp.Id,'Online');
        eoi.ComplianceStatus__c = 'Cleared';
        Insert eoi;
        
        TriggerHandler.processedIds = new Set<Id>();
        ReceiptAcknowledgement__c paymentRec = TestObjectsFactory.getReceiptAcknowledgementRecord(sa.Id, acc.Id, opp.Id, 'Online');
        paymentRec.OpportunityEOI__c = eoi.Id;
        insert paymentRec;
            
        PageReference pageRef = Page.PaymentGW;
        Test.setCurrentPage(pageRef);

        ApexPages.currentPage().getParameters().put('id',EncodingUtil.urlEncode(EncryptionUtils.encryptString(paymentRec.Id+''), 'UTF-8'));
        ApexPages.currentPage().getParameters().put('v','1234567890');

        PaymentGWController obj= new PaymentGWController();
        obj.paymentGWController1();

        ApexPages.currentPage().getParameters().put('req_transaction_uuid',paymentRec.Id +'-'+'1655120943666');
        ApexPages.currentPage().getParameters().put('payer_authentication_transaction_id','UuNTkrX0O1WE6UESLY00');
        ApexPages.currentPage().getParameters().put('reason_code','100');
        ApexPages.currentPage().getParameters().put('decision','Success');
        ApexPages.currentPage().getParameters().put('auth_trans_ref_no','123456');
        ApexPages.currentPage().getParameters().put('bill_trans_ref_no','123456');
        ApexPages.currentPage().getParameters().put('transaction_id','123456');
        ApexPages.currentPage().getParameters().put('auth_code','123456');
        ApexPages.currentPage().getParameters().put('message','123456');

        /*resp = '{"utf8":"✓","transaction_id":"6551210281356291304002","signed_field_names":"transaction_id,decision,req_access_key,req_profile_id,req_transaction_uuid,req_transaction_type,req_reference_number,req_amount,req_currency,req_locale,req_payment_method,req_bill_to_forename,req_bill_to_surname,req_bill_to_email,req_bill_to_phone,req_bill_to_address_line1,req_bill_to_address_city,req_bill_to_address_country,req_card_number,req_card_type,req_card_type_selection_indicator,req_card_expiry_date,card_type_name,req_device_fingerprint_id,req_payer_authentication_acs_window_size,req_payer_authentication_indicator,req_payer_authentication_merchant_name,payer_authentication_reason_code,payer_authentication_specification_version,payer_authentication_transaction_id,payer_authentication_enroll_veres_enrolled,payer_authentication_acs_transaction_id,message,reason_code,auth_avs_code,auth_avs_code_raw,auth_response,auth_amount,auth_code,auth_cavv_result,auth_cavv_result_raw,auth_cv_result,auth_cv_result_raw,auth_trans_ref_no,auth_time,request_token,merchant_advice_code,auth_reconciliation_reference_number,bill_trans_ref_no,payer_authentication_validate_result,payer_authentication_cavv,payer_authentication_validate_e_commerce_indicator,payer_authentication_eci,payer_authentication_pares_status,payer_authentication_xid,score_device_fingerprint_cookies_enabled,score_device_fingerprint_flash_enabled,score_device_fingerprint_hash,score_device_fingerprint_images_enabled,score_device_fingerprint_javascript_enabled,score_device_fingerprint_true_ipaddress,score_device_fingerprint_true_ipaddress_city,score_device_fingerprint_true_ipaddress_country,score_device_fingerprint_screen_resolution,score_device_fingerprint_smart_id,score_device_fingerprint_smart_id_confidence_level,score_device_fingerprint_browser_language,score_factors,score_rcode,score_time_local,score_model_used,score_return_code,score_host_severity,score_score_result,score_reason_code,score_rflag,score_rmsg,score_address_info,score_identity_info,score_internet_info,score_ip_city,score_ip_country,score_ip_state,score_ip_routing_method,score_suspicious_info,score_velocity_info,decision_early_return_code,decision_early_reason_code,decision_reason_code,decision_rmsg,decision_rcode,decision_case_priority,decision_return_code,decision_early_rcode,decision_rflag,signed_field_names,signed_date_time","signed_date_time":"2022-06-13T11:50:29Z","signature":"jQckvlCQjdAyoTQx2A3icqrsgI+RM28DF5Ntn5vo46Y=","score_velocity_info":"VEL-NAME^VELI-CC^VELI-FP^VELI-TIP^VELL-CC^VELL-FP^VELL-TIP^VELS-CC^VELS-FP^VELS-TIP^VELV-CC","score_time_local":"14:50:28","score_suspicious_info":"MUL-EM","score_score_result":"84","score_rmsg":"Score exceeds threshold. Score = 84","score_rflag":"DSCORE","score_return_code":"1072000","score_reason_code":"100","score_rcode":"1","score_model_used":"default_cemea","score_ip_state":"c","score_ip_routing_method":"fixed","score_ip_country":"eg","score_ip_city":"al qahirah","score_internet_info":"MM-IPBCO","score_identity_info":"MORPH-C","score_host_severity":"1","score_factors":"H","score_device_fingerprint_true_ipaddress_country":"EG","score_device_fingerprint_true_ipaddress_city":"al qahirah","score_device_fingerprint_true_ipaddress":"134.238.72.127","score_device_fingerprint_smart_id_confidence_level":"100.00","score_device_fingerprint_smart_id":"5091b06a8a6e42f1891129e33b267789","score_device_fingerprint_screen_resolution":"1920x1080","score_device_fingerprint_javascript_enabled":"true","score_device_fingerprint_images_enabled":"false","score_device_fingerprint_hash":"5091b06a8a6e42f1891129e33b267789","score_device_fingerprint_flash_enabled":"false","score_device_fingerprint_cookies_enabled":"true","score_device_fingerprint_browser_language":"en-US,en;q=0.9","score_address_info":"UNV-ADDR","request_token":"Axj//wSTYyROYRgInWpC/7Us2atWLJiwZOGLNq2ZOWLNg0YMGSiOPFpWDgFRHHi0rB2IEsNQCHSGTSTL0YsKuzgwVybGSJzCMBE61IQAzQdu"'
        +',"req_transaction_uuid":"a1A8E000002g6e4UAA-1655120943666","req_transaction_type":"sale","req_reference_number":"00526000009Aw2oAAC","req_profile_id":"B21DB9B8-0EB5-4E27-A963-B6A0F50A6411","req_payment_method":"card","req_payer_authentication_merchant_name":"ADCB","req_payer_authentication_indicator":"01","req_payer_authentication_acs_window_size":"03","req_locale":"en","req_device_fingerprint_id":"6f7679efc99848ab9cca72185d49bb21","req_currency":"AED","req_card_type_selection_indicator":"1","req_card_type":"001","req_card_number":"xxxxxxxxxxxx1096","req_card_expiry_date":"02-2025","req_bill_to_surname":"Moscow","req_bill_to_phone":"+962787120342","req_bill_to_forename":"Created","req_bill_to_email":"ali.athamneh@pwc.com","req_bill_to_address_line1":"amman","req_bill_to_address_country":"JO","req_bill_to_address_city":"amman","req_amount":"2000.00","req_access_key":"a9e9af7262253248901760e4a429154f","reason_code":"100","payer_authentication_xid":"MTIzNDU2Nzg5MDEyMzQ1Njc4OTA=","payer_authentication_validate_result":"0","payer_authentication_validate_e_commerce_indicator":"vbv","payer_authentication_transaction_id":"UuNTkrX0O1WE6UESLY00","payer_authentication_specification_version":"2.1.0","payer_authentication_reason_code":"100","payer_authentication_pares_status":"Y","payer_authentication_enroll_veres_enrolled":"Y","payer_authentication_eci":"05","payer_authentication_cavv":"MTIzNDU2Nzg5MDEyMzQ1Njc4OTA=","payer_authentication_acs_transaction_id":"0d700b4c-c752-4e78-a79f-ec5ab57530a4","message":"Request was processed successfully.","merchant_advice_code":"01","decision_rmsg":"Service processed successfully","decision_rflag":"SOK","decision_return_code":"1320000","decision_reason_code":"100","decision_rcode":"1","decision_early_return_code":"9999999","decision_early_reason_code":"100","decision_early_rcode":"1","decision_case_priority":"3","decision":"ACCEPT","card_type_name":"Visa","bill_trans_ref_no":"6551210281356291304002","auth_trans_ref_no":"6551210281356291304002","auth_time":"2022-06-13T115029Z","auth_response":"00","auth_reconciliation_reference_number":"216411124967","auth_cv_result_raw":"M","auth_cv_result":"M","auth_code":"831000","auth_cavv_result_raw":"2","auth_cavv_result":"2","auth_avs_code_raw":"Y","auth_avs_code":"Y","auth_amount":"2000.00"}';
        */
        obj.paymentGWController1();  
        obj.getEndp();
        obj.getValitity();
        obj.getSignedData();
        obj.getParametersValues();

        Test.stopTest();
    }
}