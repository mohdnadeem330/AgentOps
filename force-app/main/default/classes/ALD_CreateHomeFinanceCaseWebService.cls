/**********************************************************************************************************************
* Name              : ALD_CreateHomeFinanceCaseWebService                                                        
* Description       : Webservice classs to create Home Finance case 
* Method			: doPost()
* Created By        : tdontha@aldar.com - Tharun    
* Last Modified By	: tdontha@aldar.com - Tharun
******************************************************************************************************************/
@RestResource (urlMapping = '/create/homefinance/case')
global with sharing class ALD_CreateHomeFinanceCaseWebService {
    @HttpPost
    global static void doPost()
    {  
        RestContextHandler handler = new RestContextHandler(false);
        try
        {
            List<Case> caseList = new List<Case>();
            Id homeFinanceRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Home_Finance').getRecordTypeId();
            RestRequest req = RestContext.request;
            String jsonBody = req.requestBody.toString();
            ALD_HomeFinanceCaseReqWrapper caseWrapper = (ALD_HomeFinanceCaseReqWrapper)JSON.deserializeStrict(jsonBody,ALD_HomeFinanceCaseReqWrapper.class);
            
            Case caseSingle = new Case();
            caseSingle.RecordTypeId					= homeFinanceRecTypeId;
            caseSingle.HF_FirstName__c				= caseWrapper.firstName;
            caseSingle.HF_LastName__c				= caseWrapper.lastName;
            caseSingle.MobileCountryCode__c			= caseWrapper.mobileCountryCode;
            caseSingle.MobileNumber__c				= caseWrapper.mobileNumber;
            caseSingle.Email__c						= caseWrapper.email;
            caseSingle.HF_Nationality__c			= caseWrapper.nationality;
            caseSingle.HF_Residency__c				= caseWrapper.residency;
            caseSingle.HF_City__c					= caseWrapper.city;
            caseSingle.HF_EmploymentStatus__c		= caseWrapper.employmentStatus;
            caseSingle.HF_Property_type__c			= caseWrapper.employmentStatus;
            caseSingle.HF_ApproximatePropertyValue__c =  Decimal.valueOf(caseWrapper.approxPropertyValue);
            caseSingle.HF_ApproximateLoanAmountRequired__c = Decimal.valueOf(caseWrapper.approxLoanAmountRequired);
            caseSingle.Description					= caseWrapper.anyOtherInfo;
            caseSingle.SubVertical__c				= 'Home Finance';
            caseSingle.Subject						= 'HomeFinance case';
            
            caseList.add(caseSingle);
            
            if(!caseList.isEmpty()){
                insert caseList;
                handler.response.success = true;
                handler.response.data    = caseList ;
                handler.finalize();
            }
        }
        catch (DMLException exc) {
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = exc.getDMLMessage(0);
            handler.finalize(exc);
        }
        catch(Exception ex)
        {            
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            //handler.response.message = Constants.MESSAGE_GENERIC_ERROR;
            System.debug('Exception----'+ex.getMessage());
            handler.response.message = ex.getMessage();
            handler.finalize(ex);
        }
        
    }
    
}