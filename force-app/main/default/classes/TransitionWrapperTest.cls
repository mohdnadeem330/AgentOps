@IsTest 
private class TransitionWrapperTest {
    
    @IsTest(SeeAllData=true) 
    public static void transitionWrapperfields() {

        // Initializing objects
        TransitionWrapper obj = new TransitionWrapper();
        obj.objStatus = new HexaBPM__Status__c();
        obj.objSRStepTrans = new HexaBPM__Step_Transition__c();
    }    
}