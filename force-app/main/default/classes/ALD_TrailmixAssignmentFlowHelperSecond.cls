/**********************************************************************************************************************
* Name               : ALD_TrailmixAssignmentFlowHelperSecond                                                        
* Description        : 
* Created By         : 
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           Salesforce				15/06/2023      Initial Draft       
******************************************************************************************************************/
public class ALD_TrailmixAssignmentFlowHelperSecond {
 
  @InvocableMethod(label='Create Trailmix Assignment Records' 
                   description='Returns a list of Trailmix Assignments' category='Trailmix Assignment')
  public static List<ReturnVariable> getTAList(List<InputVariable> inputVariableList) {
      
      //Fetching the Ids of the Users who have already logged into mytrailhead
      List<trailheadapp__Trailmix_Assignment__c> trailmixAssignList = new List<trailheadapp__Trailmix_Assignment__c>();
      for(User eachUserData : inputVariableList.get(0).userList){
      	  trailheadapp__Trailmix_Assignment__c eachTA = new trailheadapp__Trailmix_Assignment__c();
          eachTA.trailheadapp__Due_At__c = inputVariableList.get(0).dueDate;
          eachTA.trailheadapp__Due_Datetime__c  = inputVariableList.get(0).dueDateTime;
          eachTA.trailheadapp__Trailmix__c  = inputVariableList.get(0).trailMixId;
          eachTA.trailheadapp__User__c  = eachUserData.Id;
          trailmixAssignList.add(eachTA);    
      }
      ReturnVariable response = new ReturnVariable();
      if(trailmixAssignList.size()>0){
      	response.trailmixAssignmentList = trailmixAssignList;
      }
      List<ReturnVariable> responseWrapper = new List<ReturnVariable>();
      responseWrapper.add(response);
      return responseWrapper;
  }
  public class InputVariable{
      @InvocableVariable
      public List<User> userList; 
      @InvocableVariable
      public DateTime dueDateTime;
      @InvocableVariable
      public Date dueDate;
      @InvocableVariable
      public Id trailMixId;
      
  }
    
  public class ReturnVariable{
      @InvocableVariable
      public List<trailheadapp__Trailmix_Assignment__c > trailmixAssignmentList; 
  }

}