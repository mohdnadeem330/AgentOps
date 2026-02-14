public without sharing class EncryptionUtils {
	
	public static String decryptString(String encryptedString) {

        Blob cryptoKey = Blob.valueOf(System.Label.EncryptionKey);
        system.debug('cryptoKey::'+cryptoKey);
        
        Blob encryptedData = EncodingUtil.base64Decode(encryptedString);
        Blob decryptedData = Crypto.decryptWithManagedIV('AES256', cryptoKey, encryptedData);
        String decryptedString = decryptedData.toString();
        return decryptedString;
    }

    public static String encryptString(String text) {

        Blob cryptoKey = Blob.valueOf(System.Label.EncryptionKey);
        system.debug('cryptoKey::'+cryptoKey);
        Blob data = Blob.valueOf(text);
        Blob encryptedData = Crypto.encryptWithManagedIV('AES256', cryptoKey, data);
        String encryptedString = EncodingUtil.base64encode(encryptedData);
        return encryptedString;
    }
    
     @InvocableMethod(label='FasttrackEncryption' description='Fasttrack Encryption')
    public static void encryptFastTrackAccountId(List<Id> recordIds){
        System.debug('Flow '+recordIds);
        Blob cryptoKey = Blob.valueOf(System.Label.EncryptionKey);
        Blob data = Blob.valueOf(recordIds[0]);
        Blob encryptedData = Crypto.encryptWithManagedIV('AES256', cryptoKey, data);
        String encryptedString = EncodingUtil.base64encode(encryptedData);
        try{
            Account ac = new Account(Id=recordIds[0], EncryptedRecordId__c = encryptedString);
            LeadFastTrackAccountService.skipAccountTrigger = true;
            update ac;
            LeadFastTrackAccountService.skipAccountTrigger = false;
        }catch(Exception e){
            LoggerService.save(LoggerService.addApexLog(e,'Account Fasttrack Encryption','Account Fasttrack Encryption',''));
            String htmlEmailBody = 'Hello,</br></br> Account Fasttrack Encryption failed because of below error.</br></br>'+ e.getMessage()+'--'+e.getStackTraceString();
            List<String> recipientList = Label.SysAdminEmailAddress.split(';');
            Utilities.sendEmail(new list<Messaging.SingleEmailMessage>{Utilities.getEmailInstance('','','',recipientList, new List<String>(), new List<String>(), 'Account Fasttrack Encryption faliure', '',htmlEmailBody,new List<Messaging.EmailFileAttachment>(), '')});
        }
    }
}