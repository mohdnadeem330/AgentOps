/**********************************************************************************************************************
* Name               : ALD_TrailmixAssignmentFlowHelper                                                        
* Description        : 
* Created By         : 
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           Salesforce				15/06/2023      Initial Draft       
******************************************************************************************************************/
public class ALD_TrailmixAssignmentFlowHelper {

  @InvocableMethod(label='Get User Id List' description='Returns the list of User Ids' category='User')
  public static List<ReturnVariable> getUserIdList(List<Id> trailmixId) {
      
      //Fetching the Ids of the Users who have already logged into mytrailhead
      List<Id> loggedInUserIdList = new List<Id>();
      for(trailheadapp__Trailhead_User_Data__c 
        eachUserData : [SELECT Id,trailheadapp__User__c 
                        	FROM trailheadapp__Trailhead_User_Data__c ]){
      	loggedInUserIdList.add(eachUserData.trailheadapp__User__c);    
      }
      
      /*Fetching the Ids of the Users who have already been assigned 
      to the trailmix record from which the flow is invoked*/
      List<Id> assignedUserList = new List<Id>();
      for(trailheadapp__Trailmix_Assignment__c 
        eachTrailmixAssignment : [SELECT Id, trailheadapp__User__c
                                  	FROM trailheadapp__Trailmix_Assignment__c
                                    WHERE trailheadapp__Trailmix__c =:trailmixId
                                    AND trailheadapp__Status__c  = 'Processed']){
      	assignedUserList.add(eachTrailmixAssignment.trailheadapp__User__c);    
      }
      ReturnVariable response = new ReturnVariable();
      if(loggedInUserIdList.size()>0){
      	response.loggedUserIdList = loggedInUserIdList;
      }
      if(assignedUserList.size()>0){
      	response.trailmixAssignedUseridList = assignedUserList;
      }
      List<ReturnVariable> responseWrapper = new List<ReturnVariable>();
      responseWrapper.add(response);
      return responseWrapper;
  }
	public class ReturnVariable{
        @InvocableVariable
        public List<Id> loggedUserIdList; 
        @InvocableVariable
        public List<Id> trailmixAssignedUseridList; 
    }
}