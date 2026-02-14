public without sharing class LeadDigitalBookingHelper {
    
    public static List<SendFasttrackWhatsaAppLink.FlowInputs> inputs 	= new List<SendFasttrackWhatsaAppLink.FlowInputs>();//Added by Sarah on Apr 08, 2024
    public static List<SendFasttrackWhatsaAppLink.FlowOutputs> output;
    
    public static void prepareFlowInputs(List<Lead> newList, String sourceType) {
        
        SendFasttrackWhatsaAppLink.FlowInputs input = new SendFasttrackWhatsaAppLink.FlowInputs();
        for(Lead leadRec : newList){
            input.category								= 'Booking';
            input.accountId								= leadRec.ExistingAccount__c;
            input.brokerAccountId						= leadRec.BrokerAgency__c;
            input.brokerContactId						= leadRec.BrokerAgent__c;
            input.project								= leadRec.Project__c;
            input.sourceType							= 'Broker Portal';
            input.status								= 'Link Sent';
            input.UnitId                                = leadRec.Unit__c;
            input.LeadId                                = leadRec.Id;
            inputs.add(input);
            
        }
        
        if(inputs != null && !inputs.isEmpty() && !Test.isRunningTest()) {
            output = SendFasttrackWhatsaAppLink.createDigitalExpRecord(inputs);
        }
    }   
    
    public static List<Lead> checkUnitStatus(List<Lead> brokerDigitalSaleLeads,List<Lead> newList){
        Set<Id> getUnitIds = new Set<Id>();
        for(Lead ld : newList){
            if(ld.Unit__c != null)
                getUnitIds.add(ld.Unit__c);
        }
        Map<Id,Lead> getLeadDetails = new Map<Id,Lead>(brokerDigitalSaleLeads);
        Map<Id,Unit__c> getUnitDetails = new Map<Id,Unit__c>([SELECT Id,Status__c,LockedByCustomer__c FROM Unit__c WHERE Id In : getUnitIds]);
        List<Lead> brokerLead = new List<Lead>();
        for(Lead lead : newList){
            if(getUnitDetails.containsKey(lead.unit__c) && getLeadDetails.containsKey(lead.Id)){
                Unit__c unit = getUnitDetails.get(lead.Unit__c);
                if(unit.Status__c == 'Available' || (unit.Status__c == 'In-Progress' && unit.LockedByCustomer__c == lead.ExistingAccount__c)){
                    brokerLead.add(getLeadDetails.get(lead.Id));
                } else {
                    lead.Unit__c.addError(Label.BrokerRequestReservation);
                }
            }
        }
        return brokerLead;
    }
}