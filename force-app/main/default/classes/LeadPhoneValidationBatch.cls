public class LeadPhoneValidationBatch implements Database.Batchable<sObject>, Database.AllowsCallouts 
{	
    Set<ID> leadId = new Set<ID>();
    
    public LeadPhoneValidationBatch(Set<Id> strLeadId){
        this.leadId = strLeadId;
    }
    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator('SELECT Id, MobileCountryCode__c, MobileNumber1__c, MobilePhone FROM Lead WHERE MobilePhone != null and id IN :leadId');
    }
    public void execute(Database.BatchableContext context, List<sObject> scope) {
        if (!scope.isEmpty()){
            Lead leadRecord = (Lead)scope[0];
            try {
                List<String> phoneNumbers = new List<String>{leadRecord.MobilePhone};
                    Map<String, String> result = MobileNumberValidation.validatePhoneNo(phoneNumbers);
                if (result.containsKey('IsValid')){
                    //Integer x = 1/0;
                    String isValid = result.get('IsValid');
                    leadRecord.MobileNumberisValid__c = isValid;
                    if(isValid == 'Yes' || isValid == 'Maybe'){
             if (result.containsKey('NationalFormat')) {   String nationalFormat = result.get('NationalFormat');String removeSpecialchar = nationalFormat.replaceAll('[^a-zA-Z0-9\\s+]', '');String nationalFormatwithoutspace = removeSpecialchar.replace(' ', ''); String trimmedString = nationalFormatwithoutspace.startsWith('0') ? nationalFormatwithoutspace.substring(1) : nationalFormatwithoutspace;leadRecord.Mobilenumber1__c = trimmedString; }
                        if (result.containsKey('CountryPrefix')) { leadRecord.MobileCountryCode__c = result.get('CountryPrefix');
                        }
                    }
                    update leadRecord;
                }else{
                    LoggerService.save(LoggerService.addApexServiceCalls('LeadPhoneValidationBatch','LeadPhoneValidationBatch','execute', leadRecord.MobilePhone, JSON.serialize(result) , null));
                }
            } catch (Exception e) {System.debug('Exception caught: ' + e.getMessage());LoggerService.save(LoggerService.addApexLog(e,'LeadPhoneValidationBatch','execute',''));
            }
        }
    }
    public void finish(Database.BatchableContext context) {
        // You can perform any post-processing here if needed.
    }
}