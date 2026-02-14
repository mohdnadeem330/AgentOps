public class ECSS_SendEscalationEmails {
    @InvocableMethod
    public static void sendAssignmentandEscalationEmail(
        List<ECSS_CaseSendAction> csList
    ) {
        if (csList.size() > 0) {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setTemplateId(csList[0].EmailTemplateId);
            email.setWhatId(csList[0].caseObj.Id);
            String contactId = '';
            if (
                !csList.isEmpty() &&
                csList[0].caseObj != null &&
                csList[0].caseObj.ContactId == null
            ) {
                List<Contact> cont = new List<Contact>([SELECT Id FROM Contact LIMIT 1]);
                if(cont.size()>0)
                contactId = cont[0].Id;
            } else {
                System.debug('In the else' + csList[0].caseObj.ContactId);
                contactId = csList[0].caseObj.ContactId;
            }
            System.debug('ContactId is:' + contactId);
            email.setTargetObjectId(contactId);
            email.setTreatTargetObjectAsRecipient(false);
            System.debug('csList[0].email' + csList[0].EmailList);
            List<String> recpientEmails = new List<String>();
            List<Case> caseSLA = new List<Case>();
            caseSLA.add(csList[0].caseObj);
            List<ECSS_CaseAssignmentReturn> caseAssignmentRet = ECSS_CaseAssiggnmentSLAFromMtd.getAllEscalationEmails(caseSLA);
            if (csList[0].email != null){
                // email.setToAddresses(new List<String>{ csList[0].email });
                recpientEmails.addAll(splitByComma(csList[0].email));
                if(caseAssignmentRet.size()>0){
                    if( caseAssignmentRet[0].ResponseTeam != '' && caseAssignmentRet[0].ResponseTeam != null)
                        recpientEmails.addAll(splitByComma(caseAssignmentRet[0].ResponseTeam));
                }
            }
            else {
                System.debug('in the else' + csList[0].EmailList);
                // email.setToAddresses(csList[0].EmailList);
                if(csList[0].EmailList!=null)
                recpientEmails = csList[0].EmailList;
                if(caseAssignmentRet.size()>0){
                    if( caseAssignmentRet[0].ResponseTeam != '' && caseAssignmentRet[0].ResponseTeam != null)
                        recpientEmails.addAll(splitByComma(caseAssignmentRet[0].ResponseTeam));
                }
            }
            email.setToAddresses(recpientEmails);
            String addName = System.label.ECSS_Org_Wide;
            //String khidAddName = System.label.ECSSKhidmahOrgWide;
           // String provAddName = System.label.ECSSProvisOrgWide;
            
            List<ECSS_Escalation_Email_Address__mdt> categoryMDT;
             if(csList[0].caseObj.CaseCategory__c != null && csList[0].caseObj.CaseCategory__c != '')
             {
             categoryMDT = new List<ECSS_Escalation_Email_Address__mdt>([SELECT Id, Email__c,Company__c, Incident_Category__c 
                                                                        FROM ECSS_Escalation_Email_Address__mdt 
                                                                        WHERE Incident_Category__c =:csList[0].caseObj.CaseCategory__c]); 
             
             }
            
             List<ECSS_Escalation_Email_Address__mdt> companyMDT;
             if(csList[0].caseObj.ECSS_CompanyOptions__c != null && csList[0].caseObj.ECSS_CompanyOptions__c != '')
             {
             companyMDT = new List<ECSS_Escalation_Email_Address__mdt>([SELECT Id,Email__c, Company__c, Incident_Category__c 
                                                                        FROM ECSS_Escalation_Email_Address__mdt 
                                                                        WHERE Company__c =:csList[0].caseObj.ECSS_CompanyOptions__c]);              	
             }
            
            	if(categoryMDT!=null && categoryMDT.size()>0)
             	addName = categoryMDT[0].Email__c;
            	else if(companyMDT!=null && companyMDT.size()>0)
                addName = companyMDT[0].Email__c;
            

            
           /* if(csList[0].caseObj.ECSS_CompanyOptions__c != null && csList[0].caseObj.ECSS_CompanyOptions__c != '' && csList[0].caseObj.ECSS_CompanyOptions__c =='Khidmah'){
                addName = khidAddName;
            }
            if(csList[0].caseObj.ECSS_CompanyOptions__c != null && csList[0].caseObj.ECSS_CompanyOptions__c != '' && csList[0].caseObj.ECSS_CompanyOptions__c =='Provis'){
                addName = provAddName;
            }*/
            System.debug('addName:'+addName);
            
            // Set Org-Wide Email Address as Sender
            OrgWideEmailAddress[] owea = [
                SELECT Id
                FROM OrgWideEmailAddress
                WHERE Address = :addName
                LIMIT 1
            ];
            System.debug(owea);
            if (!owea.isEmpty()) {
                email.setOrgWideEmailAddressId(owea[0].Id);
            } 
        	/*else {
                System.debug('No Org-Wide Email Address found!');
            }*/
            
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
        }
    }
    public static List<String> splitByComma(String data) {
        if (data == null) {
            return null;
        }
        List<String> resultList = new List<String>();
        // Check if the data contains a comma
        if (data.contains(',')) {
            resultList = data.split(',');
        } else {
            // If no comma, add the single data string to the list
            resultList.add(data);
        } 
        return resultList;
    }
}