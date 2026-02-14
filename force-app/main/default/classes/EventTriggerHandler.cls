/**********************************************************************************************************************
* Name               : EventTriggerHandler                                                        
* Description        : This class contains all the helper methods for the Event Trigger
* Usage              : EventTrigger
* Created By         : PWC Digital Middle East                                                     
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           paras.bhatt@pwc.com     21 May 2022      Initial Draft       
******************************************************************************************************************/
public with sharing class EventTriggerHandler extends TriggerHandler {
     
    public override void beforeDeleteMethod(List<SObject> oldList, Map<Id, SObject> oldMap){
       //prevent deletion
       User tempLoggedInUser = Utilities.getLoggedInUserDetail();
       if(tempLoggedInUser.Profile.Name != Constants.USER_PROFILE_SYSTEM_ADMINISTRATOR && tempLoggedInUser.Profile.Name != Constants.INTEGRATION_PROFILE){
           for(Event tempTask : (list<Event>) oldList ){tempTask.addError(Utilities.getSystemMessages(Constants.INSUFFICIENT_ACCESS).Message__c);
           }
       }
   }
}