/**********************************************************************************************************************  
* Name               : BrokerNOCLetterController                                                         
* Description        : This class is used to generate the NOC Document PDF from Broker Portal
* Usage              : BrokerNOCLetterPDF VF Page                                                           
* Created By         : Tharun                                                      
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           tdontha@aldar.com      4 Jul 2024       Initial Draft  
* 1.1           ChatGPT                26 Jun 2025      Fetch Primary/Owner Contact Name + Project list splitting
******************************************************************************************************************/
public class BrokerNOCLetterController {

    public String todayDate               { get; set; }
    public String endDate                 { get; set; }
    public String loggedInUserId          { get; set; }
    public String agencyName              { get; set; }
    public String agencyRegNumber         { get; set; }
    public String agencyCity              { get; set; }
    public String agencyExpiryDate        { get; set; }
    public String renderAsVal             { get; set; }
    public String NameToDisplay                   { get; set; }
    public String selectedProjectsCSV     { get; set; }

    public BrokerNOCLetterController() {
        renderAsVal = ApexPages.currentPage().getParameters().get('renderAs');
        todayDate = System.today().format();
        DateTime daysLater = Date.today().addDays(90);
        endDate = daysLater.format('dd/MMMM/yyyy');

        String fileName = 'NocLetter';
        String userId = UserInfo.getUserId();
        selectedProjectsCSV = ApexPages.currentPage().getParameters().get('projects');

        if (String.isNotBlank(userId)) {
            User loggedinUser = [
                SELECT Id, Name, ContactId, AccountId,
                	   Contact.Name,
                       Account.Name, 
                       Account.RegistrationNumber__c, 
                       Account.RegistrationExpiryDate__c,
                       Account.BillingCity, 
                       Account.BillingState
                FROM User 
                WHERE Id = :userId 
                LIMIT 1
            ];

            if (loggedinUser != null && loggedinUser.AccountId != null) {
                agencyName = String.isNotBlank(loggedinUser.Account.Name) ? loggedinUser.Account.Name : 'agency';
                agencyRegNumber = String.isNotBlank(loggedinUser.Account.RegistrationNumber__c) ? loggedinUser.Account.RegistrationNumber__c : '';
                agencyCity = String.isNotBlank(loggedinUser.Account.BillingState) ? loggedinUser.Account.BillingState : 'DUBAI';
                agencyExpiryDate = String.valueOf(loggedinUser.Account.RegistrationExpiryDate__c) != null 
                    ? String.valueOf(loggedinUser.Account.RegistrationExpiryDate__c) 
                    : '';
                fileName = String.isNotBlank(loggedinUser.Account.Name) ? loggedinUser.Account.Name + '-NocLetter' : 'agency';

                // Find primary/owner contact for this account
                Contact contactToUse;
                List<Contact> contacts = [SELECT Id, Name, AccountId, BrokerType__c,PrimaryOwner__c FROM Contact 
                    WHERE 
                    (AccountId = :loggedinUser.AccountId AND BrokerType__c = 'Partner/Owner' AND PrimaryOwner__c = true AND AgentStatus__c = 'Active')
                    OR (Id = :loggedinUser.ContactId)
                    LIMIT 2
                ];
                
                for (Contact c : contacts) {
                    if (c.AccountId == loggedinUser.AccountId && c.BrokerType__c == 'Partner/Owner' && c.PrimaryOwner__c) {
                        contactToUse = c;
                        break;
                    } else if (c.Id == loggedinUser.ContactId) {
                        contactToUse = c;                     }
                }
                System.debug(contactToUse + ' contactToUse');
                NameToDisplay = (contactToUse != null) ? contactToUse.Name : 'Admin';
            }
        }

        // Force download if rendering as PDF
        if (renderAsVal == 'pdf') {
            Apexpages.currentPage().getHeaders()
                .put('content-disposition', 'attachment; filename=' + fileName + '.pdf');
        }
    }
}