@RestResource (urlMapping = '/create/staffReferralLead')
global class createStaffReferralLeadWebService {
    
    @HttpPost
    global static void doPost(){  
        RestContextHandler handler = new RestContextHandler(false);
        try {
            String requestString = RestContext.request.requestBody.toString();
            Lead requestLead = new Lead();
            List<Boolean> isEmailValidated = new List<Boolean>();
            List<Boolean> isPhoneValidated = new List<Boolean>();
            
            requestLead = (Lead) JSON.deserialize(requestString, Lead.class);
            system.debug('requestLead::'+requestLead);
           
            List<Lead> staffLeads = [SELECT
                                     Id,
                                     Name,
                                     Status
                                     FROM Lead
                                     WHERE (Email =:requestLead.email
                                     OR MobilePhone =:(requestLead.MobileCountryCode__c + requestLead.MobileNumber1__c))
                                     ORDER BY createddate DESC];
            
            
            isEmailValidated = EmailValidation.validateEmail(new List<String>{requestLead.Email});
            isPhoneValidated = PhoneNoValidation.validatePhoneNo(new List<String>{requestLead.MobileCountryCode__c+requestLead.MobileNumber1__c});
            system.debug('isEmailValidated::'+isEmailValidated);
            system.debug('isPhoneValidated::'+isPhoneValidated);
            
            if(!isEmailValidated[0]){
                handler.response.success = false;
                handler.response.message = 'Please enter Valid Email Address';  handler.finalize();
            }else if(!isPhoneValidated[0]){
                handler.response.success = false;
                handler.response.message = 'Please enter Valid Phone Number'; handler.finalize();
            }else if(isEmailValidated[0] && isPhoneValidated[0]){ 
                if(staffLeads.size()>0){
                    handler.response.success = false;
                    handler.response.message = 'Lead with given phone or email is already present.';
                    handler.response.data = staffLeads;
                    handler.finalize();
                }
                else{
                    Id RRQueueId = [SELECT DeveloperName,Id,Name,Type FROM Group WHERE Type = 'Queue' AND DeveloperName = 'SalesManagerRRAssignmentQueue'].Id;
                   //List<User> userList = [Select Id from User Where UserName =: System.Label.StaffRefferalLeadOwner AND isActive = true];
                    requestLead.CustomerType__c = 'New Customer';
                    requestLead.SalesType__c = 'Residential Sale';
                    requestLead.LeadSource = 'Online';
                    requestLead.SalesOrigin__c = requestLead.CountryOfResidence__c == 'United Arab Emirates' ? 'Domestic':'International';
                    requestLead.EnquiryCategory__c = 'Internal Referral';
                    requestLead.EnquiryTrigger__c = 'Staff Referral';
                    requestLead.ExemptFromAssignment__c = TRUE;
                   // requestLead.AssignToRoundRobin__c = !userList.isEmpty() ? FALSE : TRUE; //Commented By Amarjeet 
                     requestLead.AssignToRoundRobin__c =  TRUE; // Added by Amarjeet
                   // requestLead.OwnerId =  !userList.isEmpty() ? userList[0].Id : RRQueueId; //Commented By Amarjeet
                    requestLead.OwnerId = RRQueueId; // Added by Amarjeet 
                    if(requestLead.PropertyUsage__c == 'Residential Property') {
                        requestLead.PropertyUsage__c = 'Residential Sale';
                    }
                   
                    insert requestLead;
                     requestLead.StaffReferralStatus__c = 'Referred';
                   // requestLead.OwnerId =  userList[0].Id; //Commented By Amarjeet
                    update requestLead;

                    handler.response.success = true;
                    handler.response.data = requestLead ;
                    handler.finalize();
                } 
            } /*else{
                handler.response.success = false;
                String message;
                
                if(!isEmailValidated[0] && !isPhoneValidated[0]){
                    message = 'Enter Valid Phone Number And Email Address';
                }else if(!isEmailValidated[0]){
                    message = 'Please enter Valid Email Address';
                }else if(!isPhoneValidated[0]){
                    message = 'Please enter Valid Phone Number';
                }
                
                handler.response.message = message;
                //handler.response.data = staffLeads;
                handler.finalize();
            } */
        }catch (DMLException exc) {
            handler.response.success = false; handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = exc.getDMLMessage(0); handler.finalize(exc);
        }catch(Exception ex) {  
            system.debug(' ex.getMessage()::'+ex.getMessage());
            handler.response.success = false;
            handler.response.statusCode = Constants.STATUS_CODE_SYSTEM_ERROR;
            handler.response.message = ex.getMessage();
            handler.finalize(ex);
        }
    }
    
   
    
    
    /* API and Payload
*   /services/apexrest/create/staffReferralLead
{
"FirstName":"Sanath",
"LastName":"HM",
"Email":"smanohar@aldar.com",
"MobileNumber1__c":"527583669",
"MobileCountryCode__c":"971",
"CountryOfResidence__c":"United Arab Emirates",
"Nationality__c":"United Arab Emirates",
"Referral_Relationship__c":"friend",
"EmployeeName__c":"Aldar Employee",
"EmployeeEmail__c":"emp@aldar.com",
"EmployeeId__c":"87654567",
"EmployeeDepartment__c":"GDS",
"Project__c":"Saadiyat Grove",
"PropertyUsage__c":"Residential Property",
"ResidentStatus__c":"Resident",
"Financing__c":"Yes"
}
*/
}