/**********************************************************************************************************************
* Name               : SentOffersListingController                                                        
* Description        : This class is used in Broker portal to show the sent offer listing
* Usage              : opportunityUnitSearch LWC                                                          
* Created By         : PWC Digital Middle East                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           paras.bhatt@pwc.com     21 Jan 2022      Initial Draft       
******************************************************************************************************************/
//Without sharing is used to query ActivityHistories
public without sharing class SentOffersListingController {
// System.UnexpectedException: There is an implementation restriction on ActivityHistories. When you query this relationship, security evaluation is implemented for users who don't have administrator permissions
    @AuraEnabled(cacheable=false)
    public static list<SentOffersListingWrapper> getActivityHistory(){
        List<SentOffersListingWrapper> sentOffersListingValues = new List<SentOffersListingWrapper>();
        User userData = UserProfileController.getUserProfileDetails();
        for(Opportunity tempOpportunity : [SELECT Project__c, Contact__r.FirstName, Contact__r.LastName,Contact__r.Email, (SELECT CompletedDateTime, subject ,Description from ActivityHistories where Subject LIKE:'%Offer Letter for the Aldar Project%' limit 10) FROM Opportunity where BrokerAgentContact__r.AccountId =: userData.Account.Id]){
            if(tempOpportunity.ActivityHistories.size() != 0){
                for (ActivityHistory activityHistoryValue : tempOpportunity.ActivityHistories) {
                    sentOffersListingValues.add(new SentOffersListingWrapper(tempOpportunity, activityHistoryValue, null));
                }
            }
        }

        for(Lead tempLead : [SELECT Project__c, firstName, lastName, Email, (SELECT CompletedDateTime, subject ,Description from ActivityHistories where Subject LIKE:'%Offer Letter for the Aldar Project%' limit 10) FROM Lead where BrokerAgent__r.AccountId =: userData.Account.Id ]){
            if(tempLead.ActivityHistories.size() != 0){
                for (ActivityHistory activityHistoryValue : tempLead.ActivityHistories) {
                    sentOffersListingValues.add(new SentOffersListingWrapper(null , activityHistoryValue, tempLead));
                }
            }
        }
        return sentOffersListingValues;
    }


    
    public class SentOffersListingWrapper {
    @AuraEnabled
    public String firstName{ get; set;}
    @AuraEnabled
    public String lastName{ get; set;}
    @AuraEnabled
    public String email{ get; set;}
    @AuraEnabled
    public String PropertyName{ get; set; }
    @AuraEnabled
    public String unitCode{ get; set;}
    @AuraEnabled
    public String sentDate{ get; set;}
    public SentOffersListingWrapper(Opportunity opportunityObject, ActivityHistory activityHistoryValue, Lead leadObject){
      String text = activityHistoryValue!=null?activityHistoryValue.Description:'';
      String projectUnit = text.substringBetween('Attachment: Offer-','-Customer');
      if (opportunityObject != null) {
        this.firstName = opportunityObject.Contact__r.FirstName;
        this.lastName = opportunityObject.Contact__r.LastName;
        this.email = opportunityObject.Contact__r.Email;
        this.PropertyName = opportunityObject.Project__c;
      }else{
        this.firstName = leadObject.FirstName;
        this.lastName = leadObject.LastName;
        this.email = leadObject.Email;
        this.PropertyName = leadObject.Project__c;
      }
      this.unitCode = projectUnit;
      this.sentDate = activityHistoryValue!=null?activityHistoryValue.CompletedDateTime.format('dd-MMM-yyyy'):'';
    }
  }
}