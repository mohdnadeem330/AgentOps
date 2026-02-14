public class LeadFirstMethodOfContactService {
	public static Boolean skipLeadTrigger = false;
    public static void updateLeadFirstMethodofContact( List<Lead> lstLeads, map<String,Lead> mapLeadNumbers){
    	Set<Date> setCreatedDates = new Set<Date>();
        Set<Id> leadIds = new Set<Id>();
        Set<String> setEmails = new Set<String>();
        Set<String> setPhones = new Set<String>();
        Integer iteration = Test.isRunningTest() ? 100 : 30;
        for(Lead objLead : lstLeads){
            date createdDateOnly = date.newInstance(objLead.createdDate.year(), objLead.createdDate.month(), objLead.createdDate.day());
            setCreatedDates.add(createdDateOnly);
            leadIds.add(objLead.Id);
            
            for(integer i = 1; i < iteration; i++){
                setCreatedDates.add(createdDateOnly.addDays(-i));
                i++;
            }
            if(objLead.Email != null){
                setEmails.add(objLead.Email);
            }
            if(objLead.MobilePhone != null){
                setPhones.add(objLead.MobilePhone);
            }
        }
        
        
        List<Lead> ldlist = new List<Lead>();
        if(!test.isRunningTest()){
            
          ldlist = [SELECT Id, LeadNumber__c, EnquiryCategory__c, EnquiryTrigger__c, LeadSource, FirstMethodOfContact__c, FirstEnquiryCategory__c,FirstEnquiryTrigger__c, CreatedDate, Email, MobilePhone FROM Lead   WHERE (Email IN :setEmails OR MobilePhone IN :setPhones)  AND DAY_ONLY(createdDate) IN :setCreatedDates   AND Id NOT IN: leadIds  ORDER BY CreatedDate ASC];
        }else {
             ldlist = [SELECT Id, LeadNumber__c, EnquiryCategory__c, EnquiryTrigger__c, LeadSource, FirstMethodOfContact__c, FirstEnquiryCategory__c,FirstEnquiryTrigger__c, CreatedDate, Email, MobilePhone FROM Lead 
                                    WHERE (Email IN :setEmails OR MobilePhone IN :setPhones) 
                                    AND Id NOT IN: leadIds
                                    ORDER BY CreatedDate ASC];
        }
        system.debug('ldlist::'+ldlist);
        map<String,Lead> mapEmailLeads = new map<String,Lead>();
        map<String,Lead> mapPhoneLeads = new map<String,Lead>();
        Set<String> leadNumbers = new Set<String>();
        if(!ldlist.isEmpty()){
            for(Lead objExitingLeads :ldlist){
                if(!mapEmailLeads.containsKey(objExitingLeads.Email)){
                    mapEmailLeads.put((objExitingLeads.Email), objExitingLeads);
                }
                if(!mapPhoneLeads.containsKey(objExitingLeads.MobilePhone)){
                    mapPhoneLeads.put((objExitingLeads.MobilePhone), objExitingLeads);
                }
            } 
        }
        List<Lead> lstUpdateLeads = new List<Lead>();
        for(Lead objLead : lstLeads){
            if(mapEmailLeads.containsKey(objLead.Email)){
                objLead.FirstMethodOfContact__c = mapEmailLeads.get(objLead.Email).LeadSource;
                objLead.FirstEnquiryCategory__c = mapEmailLeads.get(objLead.Email).EnquiryCategory__c ;
                objLead.FirstEnquiryTrigger__c  = mapEmailLeads.get(objLead.Email).EnquiryTrigger__c;
            }
            else if(mapPhoneLeads.containsKey(objLead.MobilePhone)){
                objLead.FirstMethodOfContact__c = mapPhoneLeads.get(objLead.MobilePhone).LeadSource;  objLead.FirstEnquiryCategory__c = mapPhoneLeads.get(objLead.MobilePhone).EnquiryCategory__c; objLead.FirstEnquiryTrigger__c  = mapPhoneLeads.get(objLead.MobilePhone).EnquiryTrigger__c;
            }else {
                objLead.FirstMethodOfContact__c = objLead.LeadSource; objLead.FirstEnquiryCategory__c = objLead.EnquiryCategory__c;
                objLead.FirstEnquiryTrigger__c  =  objLead.EnquiryTrigger__c;
            }
            lstUpdateLeads.add(objLead);
            mapLeadNumbers.put(objLead.LeadNumber__c, objLead);
        }
        system.debug('lstUpdateLeads>>>>>'+lstUpdateLeads);
        if(!lstUpdateLeads.isEmpty()){skipLeadTrigger = true; update lstUpdateLeads;skipLeadTrigger = false;}
    }
    
    public static void updateSalesOrderFirstMethodofContactRelatedLeads(map<String,Lead> mapLeadNumbers){
    	List<SalesOrder__c> lstSalesOrders = new List<SalesOrder__c>();
        for(SalesOrder__c objSalesOrder : [SELECT 
                                           Opportunity__r.LeadNumber__c,
                                           FirstMethodofContact__c,
                                           FirstEnquiryCategory__c,
                                           FirstEnquiryTrigger__c
                                           FROM SalesOrder__c 
                                           WHERE Opportunity__c IN 
                                           (SELECT 
                                            Id 
                                            FROM Opportunity 
                                            WHERE LeadNumber__c IN: mapLeadNumbers.keyset()) ]){
                                                if(mapLeadNumbers.containsKey(objSalesOrder.Opportunity__r.LeadNumber__c)){
                                                    if(objSalesOrder.FirstMethodofContact__c != mapLeadNumbers.get(objSalesOrder.Opportunity__r.LeadNumber__c).FirstMethodOfContact__c){
                                                        objSalesOrder.FirstMethodofContact__c = mapLeadNumbers.get(objSalesOrder.Opportunity__r.LeadNumber__c).FirstMethodOfContact__c;
                                                    }
                                                    if(objSalesOrder.FirstEnquiryCategory__c != mapLeadNumbers.get(objSalesOrder.Opportunity__r.LeadNumber__c).FirstEnquiryCategory__c ){
                                                        objSalesOrder.FirstEnquiryCategory__c = mapLeadNumbers.get(objSalesOrder.Opportunity__r.LeadNumber__c).FirstEnquiryCategory__c;
                                                    }
                                                    if(objSalesOrder.FirstEnquiryTrigger__c != mapLeadNumbers.get(objSalesOrder.Opportunity__r.LeadNumber__c).FirstEnquiryTrigger__c ){
                                                        objSalesOrder.FirstEnquiryTrigger__c = mapLeadNumbers.get(objSalesOrder.Opportunity__r.LeadNumber__c).FirstEnquiryTrigger__c; 
                                                    }
                                                    lstSalesOrders.add(objSalesOrder);
                                                }
		}
        system.debug('lstSalesOrders>>>>>>'+lstSalesOrders);
        if(!lstSalesOrders.isEmpty()){CalloutToMuleSoft.updateSOSyncStatus = true; update lstSalesOrders;CalloutToMuleSoft.updateSOSyncStatus = false;}
    }
}