trigger UpdateStepStatusTrigger on Update_Step_Status_Event__e (after insert) {
	List<HexaBPM__Step__c> stepList = new List<HexaBPM__Step__c>();
    
	for (Update_Step_Status_Event__e event : Trigger.New) {
        if(String.IsNotBlank(event.Status_from_Email__c)) { 
            HexaBPM__Step__c step = new HexaBPM__Step__c();
            step.Id = event.Step_Id__c;
            step.HexaBPM__Status__c = event.Status_from_Email__c;
            stepList.add(step);
        }
    }
    
    if(!stepList.IsEmpty()) {
        update stepList;
    }
}