/**
 * Created By Saravanan Sekar
 * Purpose : One time email to Lagoons project
 * Can be Deleted once emails are triggered
 * Created on 04/12/2023
 */ 
public class ALD_CustomerMilestoneChangeHelper { 

    public static Messaging.SingleEmailMessage processAndSendEmail(string targetObject,string whatId ,string templateId, List<String> toRecipients,string orgWideEmailAddressID) {
        System.debug('##$ Send email to '+toRecipients+' >> whatId >> '+whatId);
        Messaging.SingleEmailMessage tempEmailInstance = new Messaging.SingleEmailMessage();
        tempEmailInstance = Utilities.getEmailInstance(whatId,templateId,targetObject,toRecipients,null,null,null,null,null,null,orgWideEmailAddressID);
        
        tempEmailInstance.setSaveAsActivity(true);
        System.debug('### Send email targetObject '+targetObject);
        
        return tempEmailInstance;
        
        //Utilities.sendEmail(new list<Messaging.SingleEmailMessage>{tempEmailInstance});
    }
    
    
}