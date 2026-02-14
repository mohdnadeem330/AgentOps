/******************************************************************************************
 *  Name        : TransitionWrapper 
 *  Company     : PwC
 *  Date        : 06-Jun-2020
 *  Description : Class for TransitionWrapper
 ----------------------------------------------------------------------------------------  */
 public class TransitionWrapper {
	@AuraEnabled
    public HexaBPM__Status__c objStatus{get;set;}
    @AuraEnabled
    public HexaBPM__Step_Transition__c objSRStepTrans{get;set;}
}