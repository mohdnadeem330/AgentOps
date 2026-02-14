public class ECSS_CaseEmailTemplateAssignment {
    
    @invocableMethod
    public static List<CaseEmailWrapper> getEmailTemplate(List<Case> caseList){
        
        List<ECSS_Case_Email_Template__mdt> emailCaseMdtList = new List<ECSS_Case_Email_Template__mdt>([SELECT Category__c, Object_Category__c,Sub_Vertical__c,
                                                                                                        Email_Template_Name__c,Status__c,Active_Template__c,IFM_Template_Name__c,
                                                                                                        Type__c FROM ECSS_Case_Email_Template__mdt where Active_Template__c=true ]);
        Map<String,String> emailCaseMdtMap = new Map<String,String>();
        ECSS_Case_Email_Template__mdt MaintenanceTemplate = new ECSS_Case_Email_Template__mdt();
        for(ECSS_Case_Email_Template__mdt ecm: emailCaseMdtList)
        {
            if(ecm.IFM_Template_Name__c != null)
                MaintenanceTemplate = ecm;
            if(ecm.Object_Category__c != null && ecm.Object_Category__c != ''&& ecm.Category__c!=null && ecm.Category__c!='' )
                emailCaseMdtMap.put(ecm.type__c+'|'+ecm.Category__c+'|'+ecm.Object_Category__c+'|'+ecm.status__c,ecm.Email_Template_Name__c); 
            else if (ecm.Object_Category__c != null && ecm.Object_Category__c != ''&& ecm.Sub_vertical__c!=null && ecm.Sub_Vertical__c!='')
                emailCaseMdtMap.put(ecm.type__c+'|'+ecm.Sub_Vertical__c+'|'+ecm.Object_Category__c+'|'+ecm.status__c,ecm.Email_Template_Name__c); 
            if(ecm.Category__c!=null && ecm.Category__c!='')
                emailCaseMdtMap.put(ecm.type__c+'|'+ecm.Category__c+'|'+ecm.status__c,ecm.Email_Template_Name__c); 
            else if(ecm.Sub_vertical__c!=null && ecm.Sub_Vertical__c!='')
                emailCaseMdtMap.put(ecm.type__c+'|'+ecm.Sub_Vertical__c +'|'+ecm.status__c,ecm.Email_Template_Name__c);
        }
        List<caseEmailWrapper> emailTemplateList = new List<caseEmailWrapper>();
        CaseEmailWrapper ceWrap;
        String recordTypeName;
        for(Case caseTemp: caseList)
        {	ceWrap = new CaseEmailWrapper();
         
         recordTypeName = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosById().get(caseTemp.recordTypeId).getName().replace('ECSS ', '');
         system.debug('recc:'+recordTypeName+'|'+caseTemp.CaseCategory__c+'|'+caseTemp.status);
         system.debug('recc:'+recordTypeName+'|'+caseTemp.SubVertical__c+'|'+caseTemp.status);
         system.debug(emailCaseMdtMap);
         System.debug('Case:'+caseTemp);
         //IFM
         if(caseTemp.Recordtype_Name__c.contains('Maintenance') &&  caseTemp.ECSS_Contract__c != null && caseTemp.ECSS_SAPSalesOrganization__c == '1300'){
             ceWrap.caseId = caseTemp.Id;
             ceWrap.EmailTemplate = MaintenanceTemplate.IFM_Template_Name__c;
             System.debug('IFMEmailTemplate: '+ceWrap.EmailTemplate);
             emailTemplateList.add(ceWrap);
         }
         
         //Khidmah 
         else if(caseTemp.Recordtype_Name__c.contains('Maintenance') &&  caseTemp.ECSS_CompanyOptions__c == 'Khidmah' ){
             ceWrap.caseId = caseTemp.Id;
             ceWrap.EmailTemplate = MaintenanceTemplate.Email_Template_Name__c;
             System.debug('EmailTemplate: '+ceWrap.EmailTemplate);
             emailTemplateList.add(ceWrap);
         }
         else if(emailCaseMdtMap.containsKey(recordTypeName+'|'+caseTemp.CaseCategory__c+'|'+caseTemp.ECSS_Object_Category__c+'|'+caseTemp.status))
         {
            System.debug('CATEGORY OBJECT');
             ceWrap.caseId = caseTemp.Id;
             ceWrap.EmailTemplate = emailCaseMdtMap.get(recordTypeName+'|'+caseTemp.CaseCategory__c+'|'+caseTemp.ECSS_Object_Category__c+'|'+caseTemp.status);
             System.debug('EmailTemplate: '+ceWrap.EmailTemplate);
             emailTemplateList.add(ceWrap);

         }
          else if(emailCaseMdtMap.containsKey(recordTypeName+'|'+caseTemp.SubVertical__c+'|'+caseTemp.ECSS_Object_Category__c+'|'+caseTemp.status))
         {
            System.debug('SubVertical OBJECT');
             ceWrap.caseId = caseTemp.Id;
             ceWrap.EmailTemplate = emailCaseMdtMap.get(recordTypeName+'|'+caseTemp.SubVertical__c+'|'+caseTemp.ECSS_Object_Category__c+'|'+caseTemp.status);
             System.debug('EmailTemplate: '+ceWrap.EmailTemplate);
             emailTemplateList.add(ceWrap);

         }
                  
         else if(emailCaseMdtMap.containsKey(recordTypeName+'|'+caseTemp.CaseCategory__c+'|'+caseTemp.status))
         {
             system.debug('CATEGORY');
             ceWrap.caseId = caseTemp.Id;
             ceWrap.EmailTemplate = emailCaseMdtMap.get(recordTypeName+'|'+caseTemp.CaseCategory__c+'|'+caseTemp.status);
             emailTemplateList.add(ceWrap);
         }
         else if(emailCaseMdtMap.containsKey(recordTypeName+'|'+caseTemp.SubVertical__c+'|'+caseTemp.status))
         {
             System.debug('SUBVERTICAL');
             ceWrap.caseId = caseTemp.Id;
             ceWrap.EmailTemplate = emailCaseMdtMap.get(recordTypeName+'|'+caseTemp.SubVertical__c+'|'+caseTemp.status);
             System.debug('EmailTemplate: '+ceWrap.EmailTemplate);
             emailTemplateList.add(ceWrap);
             
         }
         
        }
        system.debug(emailTemplateList);
        return emailTemplateList;
        
    }
    public class CaseEmailWrapper{
        @InvocableVariable
        public String EmailTemplate;
        @InvocableVariable
        public String CaseId;
    }
    
}