public with sharing class SRAmendmentTriggerHandler extends TriggerHandler{
    public override void beforeInsertMethod(list<SObject> newList,Map<Id, SObject> newMap){
        Map<String, Decimal> srMap = sharePercentageForaSR(newList);
        /*
* Logic: Create Uniquq Key and Check all Joint Owner Share Percentage should be 99 or below
*/
        List<Id> accountIds = new List<Id>();
        List<Id> srIds = new List<Id>();
        
        for (AgencyTeam__c at: (list<AgencyTeam__c>) newList) {
            if (at.RecordTypeName__c == Constants.JOINT_OWNER_RT) {
                accountIds.add(at.Account__c);
                at.UniqueKey__c = at.ServiceRequest__c + '_' + at.Account__c;
                //bY adarsh
                if (at.RecordTypeName__c == Constants.JOINT_OWNER_RT) {
                    ComplianceCheck(at);  
                }
                
                if (at.ShareHoldingPercentage__c != null) {
                    Decimal sharePercentage = srMap.containsKey(at.ServiceRequest__c) ? srMap.get(at.ServiceRequest__c) + (at.ShareHoldingPercentage__c) : at.ShareHoldingPercentage__c;
                    if (sharePercentage > 99 && (at.ServiceRequestRecordType__c == constants.PROPERTY_TRANSFER_RT || at.ServiceRequestRecordType__c == constants.PLOT_PROPERTY_TRANSFER_RT || at.ServiceRequestRecordType__c == constants.PROPERTY_TRANSFER_NOC_RT)) {
                        System.debug('Line 14');
                        at.addError('Total Share Percentage cannot exceed 99%');
                    } else if (sharePercentage > 100 && (at.ServiceRequestRecordType__c == constants.JOINT_OWNER_RT || at.ServiceRequestRecordType__c == constants.JOINT_OWNER_NOC_RT)) {
                        System.debug('Line 17');
                        //at.addError('Total Share Percentage cannot exceed 99%');
                    }
                }
                srIds.add(at.ServiceRequest__c);
            }
        }
        
        Map<Id, Account> accountMap = new Map<Id, Account>([SELECT Id, Name FROM Account WHERE Id IN: accountIds]);
        for (AgencyTeam__c at: (list<AgencyTeam__c>) newList) {
            at.Name = accountMap.containsKey(at.Account__c) ? accountMap.get(at.Account__c).Name : at.Name;
        }
        
        if (!srIds.isEmpty()) {
            UpdateSRWithJointOwnerDetailsFuture(srIds);
        }
    }
    
    //*** Before Update Action***//
    public override void beforeUpdateMethod(list<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap){
        Map<String, Decimal> srMap = sharePercentageForaSR(newList);
        /*
* Logic: Create Uniquq Key and Check all Joint Owner Share Percentage should be 99 or below
*/
        Map<Id, Decimal> jointOwnerNewPercentageMap = new Map<Id, Decimal>();
        Map<Id, Decimal> jointOwnerOldPercentageMap = new Map<Id, Decimal>();
        String serviceRequestType = '';
        List<Id> srIds = new List<Id>();
        
        //added by Dharnesh for nintexdocgen issue Start
        
        List<Id> accountIds = new List<Id>();
        List<Id> serviceRequestIds = new List<Id>();
        List<Account> accList = new List<Account>();
        List<HexaBPM__Service_Request__c> srList = new List<HexaBPM__Service_Request__c>();
        for (AgencyTeam__c sr : (list<AgencyTeam__c>)newList) {
            if (sr.Account__c != null) {
                accountIds.add(sr.Account__c);
            }
            if (sr.ServiceRequest__c != null) {
                serviceRequestIds.add(sr.ServiceRequest__c);
            }
        }
        if (!accountIds.isEmpty()) {
            accList = [SELECT Id, Name, NameInArabic__c,
                       Nationality__pc, NationalityinArabic__pc, PassportNumber__pc
                       FROM Account WHERE Id IN :accountIds];
        }
        if (!accountIds.isEmpty()) {
            srList = [SELECT Id,JointOwnerNames__c,
                      JointOwnerNamesinArabic__c,JointOwnerNationalities__c,
                      JointOwnerNationalitiesinArabic__c,JointOwnerPassportNumbers__c
                      FROM HexaBPM__Service_Request__c WHERE Id IN :serviceRequestIds];
        }
        Map<Id, Account> accData = new Map<Id, Account>(accList);
        Map<Id, HexaBPM__Service_Request__c> srData = new Map<Id, HexaBPM__Service_Request__c>(srList);
        ////added by Dharnesh for nintexdocgen issue End
        
        for (AgencyTeam__c at: (list<AgencyTeam__c>) newList) {
            ComplianceCheck(at); 
            if (at.RecordTypeName__c == Constants.JOINT_OWNER_RT) {
                AgencyTeam__c oldAT = (AgencyTeam__c)oldmap.get(at.Id);
                if (at.Account__c != oldAT.Account__c) {
                    at.UniqueKey__c = at.ServiceRequest__c + '_' + at.Account__c;
                    srIds.add(at.ServiceRequest__c);
                } else if (at.ShareHoldingPercentage__c != oldAT.ShareHoldingPercentage__c) {
                    srIds.add(at.ServiceRequest__c);
                }
                //added by Dharnesh for nintex docgen issue Start
                else {
                    
                    HexaBPM__Service_Request__c serviceRequest = srData.get(at.ServiceRequest__c);
                    Account account = accData.get(at.Account__c);
                    
                    Boolean namesMismatch = !safeStringContains(serviceRequest.JointOwnerNames__c, account.Name);
                    Boolean arabicNamesMismatch = !safeStringContains(serviceRequest.JointOwnerNamesinArabic__c, account.NameInArabic__c);
                    Boolean nationalitiesMismatch = !safeStringContains(serviceRequest.JointOwnerNationalities__c, account.Nationality__pc);
                    Boolean arabicNationalitiesMismatch = !safeStringContains(serviceRequest.JointOwnerNationalitiesinArabic__c, account.NationalityinArabic__pc);
                    Boolean passportsMismatch = !safeStringContains(serviceRequest.JointOwnerPassportNumbers__c, account.PassportNumber__pc);
                    
                    if (namesMismatch || arabicNamesMismatch || nationalitiesMismatch || 
                        arabicNationalitiesMismatch || passportsMismatch) {
                            
                            srIds.add(at.ServiceRequest__c);
                        }
                    
                } 
                //added by Dharnesh for nintex docgen issue Start
                
                if (at.ShareHoldingPercentage__c != null && srMap.containsKey(at.ServiceRequest__c)) {
                    if (jointOwnerNewPercentageMap.containsKey(at.ServiceRequest__c)) {
                        jointOwnerNewPercentageMap.put(at.ServiceRequest__c, jointOwnerNewPercentageMap.get(at.ServiceRequest__c) + at.ShareHoldingPercentage__c);
                        jointOwnerOldPercentageMap.put(at.ServiceRequest__c, jointOwnerOldPercentageMap.get(at.ServiceRequest__c) + oldAT.ShareHoldingPercentage__c);
                    } else {
                        jointOwnerNewPercentageMap.put(at.ServiceRequest__c, at.ShareHoldingPercentage__c);
                        jointOwnerOldPercentageMap.put(at.ServiceRequest__c, oldAT.ShareHoldingPercentage__c);
                    }
                    serviceRequestType = at.ServiceRequestRecordType__c;
                    // Decimal sharePercentage = srMap.get(at.ServiceRequest__c) + (at.ShareHoldingPercentage__c - (oldAT.ShareHoldingPercentage__c != null ? oldAT.ShareHoldingPercentage__c : 0));
                    // if (sharePercentage > 99 && (at.ServiceRequestRecordType__c == constants.PROPERTY_TRANSFER_RT || at.ServiceRequestRecordType__c == constants.PLOT_PROPERTY_TRANSFER_RT || at.ServiceRequestRecordType__c == constants.PROPERTY_TRANSFER_NOC_RT)) {
                    //     System.debug('Line 42');
                    //     at.addError('Total Share Percentage cannot exceed 99%');
                    // } else if (sharePercentage > 100 && (at.ServiceRequestRecordType__c == constants.JOINT_OWNER_RT || at.ServiceRequestRecordType__c == constants.JOINT_OWNER_NOC_RT)) {
                    //     System.debug('Line 45');
                    //     at.addError('Total Share Percentage cannot exceed 99%');
                    // }
                }
            }
   
        }
        for(String key: jointOwnerNewPercentageMap.keySet()){
            Decimal sharePercentage = srMap.get(key) !=null ? srMap.get(key) :0 + jointOwnerNewPercentageMap.get(key) - jointOwnerOldPercentageMap.get(key);
            if (sharePercentage > 99 && (serviceRequestType == constants.PROPERTY_TRANSFER_RT || serviceRequestType == constants.PLOT_PROPERTY_TRANSFER_RT || serviceRequestType == constants.PROPERTY_TRANSFER_NOC_RT)) {
                System.debug('Line 63');
                newList[0].addError('Total Share Percentage cannot exceed 99%');
            } else if (sharePercentage > 100 && (serviceRequestType == constants.JOINT_OWNER_RT || serviceRequestType == constants.JOINT_OWNER_NOC_RT)) {
                System.debug('Line 67');
                newList[0].addError('Total Share Percentage cannot exceed 100%');
            }
        }
        if (!srIds.isEmpty()) {
            UpdateSRWithJointOwnerDetailsFuture(srIds);
        }
    }
    
    /*
* Logic: Get the Sum of All Joint Owner Percentage from a Service Request
*/
    public static Map<String, Decimal> sharePercentageForaSR(list<AgencyTeam__c> agencyTeamList) {
        Set<String> srIds = new Set<String>();
        // Map<Id, Decimal> jointOwnerPercentageMap = new Map<Id, Decimal>();
        for (AgencyTeam__c agencyTeam: agencyTeamList) {
            srIds.add(agencyTeam.ServiceRequest__c);
            // jointOwnerPercentageMap.put(agencyTeam.Id, agencyTeam.ShareHoldingPercentage__c);
        }
        Map<String, Decimal> srMap = new Map<String, Decimal>();
        List<HexaBPM__Service_Request__c> srList = [SELECT Id, (SELECT Id, ShareHoldingPercentage__c FROM Partners__r) FROM HexaBPM__Service_Request__c WHERE Id IN :srIds];
        for (HexaBPM__Service_Request__c sr: srList) {
            Decimal sharePercentage = 0;
            if (!sr.Partners__r.isEmpty()) {
                for (AgencyTeam__c agencyTeam: sr.Partners__r) {
                    // sharePercentage += jointOwnerPercentageMap.containsKey(agencyTeam.Id) ? jointOwnerPercentageMap.get(agencyTeam.Id) : agencyTeam.ShareHoldingPercentage__c != null ? agencyTeam.ShareHoldingPercentage__c : 0;
                    sharePercentage += agencyTeam.ShareHoldingPercentage__c != null ? agencyTeam.ShareHoldingPercentage__c : 0;
                }
                srMap.put(sr.Id, sharePercentage);
            }
        }
        return srMap;
    }
    
    //Added by Adarsh for complaiance check
    public static void ComplianceCheck(AgencyTeam__c serviceRequest) {
        if (serviceRequest.Account__c != null) {
            Account accountToUpdate = new Account(Id = serviceRequest.Account__c, Trigger_screening_Case__c = true);
            update accountToUpdate;
        }
    }
    
    @future
    
    public static void UpdateSRWithJointOwnerDetailsFuture(List<Id> srIds) {
        List<HexaBPM__Service_Request__c> srList = ServiceRequestService.queryAllFieldsWithExtraFields(srIds);
        
        Map<Id, List<AgencyTeam__c>> joMap = new Map<Id, List<AgencyTeam__c>>();
        for (HexaBPM__Service_Request__c serviceRequest: srList) {
            for (AgencyTeam__c jointOwner: serviceRequest.Partners__r) {
                if (!joMap.isEmpty() && joMap.containsKey(jointOwner.ServiceRequest__c)) {
                    List<AgencyTeam__c> joList = joMap.get(jointOwner.ServiceRequest__c);
                    joList.add(jointOwner);
                    joMap.put(jointOwner.ServiceRequest__c, joList);
                } else {
                    joMap.put(jointOwner.ServiceRequest__c, new List<AgencyTeam__c>{jointOwner});
                }
            }
        }
        Set<Id> srIdSet = new Set<Id>();
        srIdSet.addAll(srIds);
        List<HexaBPM__Service_Request__c> updateSRs = new List<HexaBPM__Service_Request__c>();
        for (Id srId: srIdSet) {
            String jointOwnerNames = '';
            String jointOwnerNamesinArabic = '';
            String jointOwnerNationalities = '';
            String jointOwnerNationalitiesinArabic = '';
            String jointOwnerPassportNumbers = '';
            String jointOwnerSharePercentages = '';
            for (AgencyTeam__c jointOwner: joMap.get(srId)) {
                jointOwnerNames += jointOwner.Account__c != null && jointOwner.Account__r.Name != null ? ' and ' + jointOwner.Account__r.Name : '';
                jointOwnerNamesinArabic += jointOwner.Account__c != null && jointOwner.Account__r.NameInArabic__c != null ? ' و ' + jointOwner.Account__r.NameInArabic__c : '';
                jointOwnerNationalities += jointOwner.Account__c != null && jointOwner.Account__r.Nationality__pc != null ? ' / ' + jointOwner.Account__r.Nationality__pc : '';
                jointOwnerNationalitiesinArabic += jointOwner.Account__c != null && jointOwner.Account__r.NationalityinArabic__pc != null ? ' / ' + jointOwner.Account__r.NationalityinArabic__pc : '';
                jointOwnerPassportNumbers += jointOwner.Account__c != null && jointOwner.Account__r.PassportNumber__pc != null ? ' / ' + jointOwner.Account__r.PassportNumber__pc : '';
                jointOwnerSharePercentages += jointOwner.ShareHoldingPercentage__c != null ? ' , ' + jointOwner.ShareHoldingPercentage__c + '%' : '';
            }
            
            HexaBPM__Service_Request__c sr = new HexaBPM__Service_Request__c();
            sr.Id = srId;
            sr.JointOwnerNames__c = jointOwnerNames;
            sr.JointOwnerNamesinArabic__c = jointOwnerNamesinArabic;
            sr.JointOwnerNationalities__c = jointOwnerNationalities;
            sr.JointOwnerNationalitiesinArabic__c = jointOwnerNationalitiesinArabic;
            sr.JointOwnerPassportNumbers__c = jointOwnerPassportNumbers;
            sr.JointOwnerSharePercentages__c = jointOwnerSharePercentages;
            updateSRs.add(sr);
        }
        if (!updateSRs.isEmpty()) {
            update updateSRs;
        }
    }
    
    //added by Dharnesh for nintex docgen issue
    private Boolean safeStringContains(String sourceString, String searchString) {
        if (String.isBlank(sourceString) || String.isBlank(searchString)) {
            return false;
        }
        return sourceString.contains(searchString);
    }
}