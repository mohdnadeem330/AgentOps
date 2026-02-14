public class DDRNotificationToBankPDFHandler {
    
    
    public Static void sendcsv(List<DDTransaction__c> ddTransactionList){
        string sentToBankStatus = 'Sent to Bank';
        string ackStatus = 'ACK';
        string RequestType = 'New Registration';
        string CollectionRequestType = 'Collection';
        string CancellationRequestType = 'Cancellation';
        try{  
           /* ddTransactionList = [SELECT DDBankingReferenceNumber__c, DDBank__c, DDResponseFileName__c, Name,  Requesttype__c, RequestFileName__c, TransactionStatus__c, DirectDebitRequest__r.PayerIdentification__c, DirectDebitRequest__r.CustomerBankName__c, DirectDebitRequest__r.CustomerAccountName__c , DirectDebitRequest__r.DirectDebitBank__c, DirectDebitRequest__r.SentTobankDate__c, DirectDebitRequest__r.Name FROM DDTransaction__c 
                                     WHERE (TransactionStatus__c=:sentToBankStatus OR TransactionStatus__c=:ackStatus) AND ( (DirectDebitRequest__r.DirectDebitBank__c ='Abu Dhabi Commercial Bank' AND ((DirectDebitRequest__r.SentToBankDays__c >= 3 AND Requesttype__c =: RequestType) 
                                                                                                                                                                                                         OR (DirectDebitRequest__r.SentToBankDays__c >= 1 AND (Requesttype__c =: CollectionRequestType OR Requesttype__c =: CancellationRequestType))))  
                                                                                                                            OR (DirectDebitRequest__r.DirectDebitBank__c ='First Abu Dhabi Bank' AND ((DirectDebitRequest__r.SentToBankDays__c >= 5 AND Requesttype__c =: RequestType) OR (DirectDebitRequest__r.SentToBankDays__c >= 1 AND (Requesttype__c =: CollectionRequestType OR Requesttype__c =: CancellationRequestType)))))];*/
          
        
            Map<String, List<DDTransaction__c>> bankDDtransactionMap = new Map<String, List<DDTransaction__c>>();
            Map<String, Map<String, List<DDTransaction__c>>> statusDDtransactionMap = new Map<String,Map<String,List<DDTransaction__c>>>();
            
         
            Map<String, Map<String, List<DDTransaction__c>>> CollectionstatusDDtransactionMap = new Map<String,Map<String,List<DDTransaction__c>>>();
            Map<String, Map<String, List<DDTransaction__c>>> CancellationstatusDDtransactionMap = new Map<String,Map<String,List<DDTransaction__c>>>();
            
            Map<String, List<String>> emailMap = new Map<String, List<String>>();
            List<String> emailList = new List<String>();
            List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
            
            for(DDTransaction__c ddTransaction : ddTransactionList){
                List<DDTransaction__c> ddTlist = bankDDtransactionMap.get(ddTransaction.DirectDebitRequest__r.DirectDebitBank__c) != null ? bankDDtransactionMap.get(ddTransaction.DirectDebitRequest__r.DirectDebitBank__c) : new List<DDTransaction__c>();
                ddTlist.add(ddTransaction);
                bankDDtransactionMap.put(ddTransaction.DirectDebitRequest__r.DirectDebitBank__c, ddTlist) ;
                
                if(ddTransaction.Requesttype__c == 'New Registration'){
                    Map<String, List<DDTransaction__c>> ackddtMap = new Map<String, List<DDTransaction__c>>();
                    ackddtMap = statusDDtransactionMap.get(ddTransaction.DirectDebitRequest__r.DirectDebitBank__c) != null ? statusDDtransactionMap.get(ddTransaction.DirectDebitRequest__r.DirectDebitBank__c) : new Map<String, List<DDTransaction__c>>();
                    List<DDTransaction__c> statusddTlist = ackddtMap.get(ddTransaction.TransactionStatus__c) != null? ackddtMap.get(ddTransaction.TransactionStatus__c) : new List<DDTransaction__c>();
                    statusddTlist.add(ddTransaction);
                    ackddtMap.put(ddTransaction.TransactionStatus__c, statusddTlist);
                    statusDDtransactionMap.put(ddTransaction.DirectDebitRequest__r.DirectDebitBank__c, ackddtMap);
                }else if(ddTransaction.Requesttype__c == 'Collection'){
                    Map<String, List<DDTransaction__c>> ackddtMap = new Map<String, List<DDTransaction__c>>();
                    ackddtMap = CollectionstatusDDtransactionMap.get(ddTransaction.DirectDebitRequest__r.DirectDebitBank__c) != null ? CollectionstatusDDtransactionMap.get(ddTransaction.DirectDebitRequest__r.DirectDebitBank__c) : new Map<String, List<DDTransaction__c>>();
                    List<DDTransaction__c> statusddTlist = ackddtMap.get(ddTransaction.TransactionStatus__c) != null? ackddtMap.get(ddTransaction.TransactionStatus__c) : new List<DDTransaction__c>();
                    statusddTlist.add(ddTransaction);
                    ackddtMap.put(ddTransaction.TransactionStatus__c, statusddTlist);
                    CollectionstatusDDtransactionMap.put(ddTransaction.DirectDebitRequest__r.DirectDebitBank__c, ackddtMap); 
                } else if(ddTransaction.Requesttype__c == 'Cancellation'){
                    Map<String, List<DDTransaction__c>> ackddtMap = new Map<String, List<DDTransaction__c>>();
                    ackddtMap = CancellationstatusDDtransactionMap.get(ddTransaction.DirectDebitRequest__r.DirectDebitBank__c) != null ? CancellationstatusDDtransactionMap.get(ddTransaction.DirectDebitRequest__r.DirectDebitBank__c) : new Map<String, List<DDTransaction__c>>();
                    List<DDTransaction__c> statusddTlist = ackddtMap.get(ddTransaction.TransactionStatus__c) != null? ackddtMap.get(ddTransaction.TransactionStatus__c) : new List<DDTransaction__c>();
                    statusddTlist.add(ddTransaction);
                    ackddtMap.put(ddTransaction.TransactionStatus__c, statusddTlist);
                    CancellationstatusDDtransactionMap.put(ddTransaction.DirectDebitRequest__r.DirectDebitBank__c, ackddtMap); 
                }
            }
      //  system.debug('bankDDtransactionMap::'+bankDDtransactionMap);
        //system.debug('CollectionstatusDDtransactionMap::'+CollectionstatusDDtransactionMap);
        if(System.Label.DDRNotificationToBankEmailRecipientsFAB.contains(',')){
                emailMap.put( 'First Abu Dhabi Bank', System.Label.DDRNotificationToBankEmailRecipientsFAB.split(','));
            }else {
                emailMap.put( 'First Abu Dhabi Bank', new List<String>{System.Label.DDRNotificationToBankEmailRecipientsFAB});
            }
            if(System.Label.DDRNotificationToBankEmailRecipientsADCB.contains(',')){
                emailMap.put( 'Abu Dhabi Commercial Bank', System.Label.DDRNotificationToBankEmailRecipientsADCB.split(','));
            }else {
                emailMap.put( 'Abu Dhabi Commercial Bank', new List<String>{System.Label.DDRNotificationToBankEmailRecipientsADCB});
            }
            
            OrgWideEmailAddress owea  = [SELECT 
                                             Id,
                                             Address,
                                             DisplayName
                                             FROM OrgWideEmailAddress
                                             WHERE DisplayName='Aldar Properties'];
            
            for(String bankName: bankDDtransactionMap.keySet()){
                String csvColumnHeader;
                List<String> csvRowValues = new List<String>();
                List<DDTransaction__c> ddTlist = bankDDtransactionMap.get(bankName);
                Map<String, List<DDTransaction__c>> stDDTMap = statusDDtransactionMap.get(bankName);
                Map<String, List<DDTransaction__c>> CollectionstDDTMap = CollectionstatusDDtransactionMap.get(bankName);
                Map<String, List<DDTransaction__c>> CancellationDDTMap = CancellationstatusDDtransactionMap.get(bankName);
                system.debug('CollectionstDDTMap::'+CollectionstDDTMap);
                
                for(DDTransaction__c ddt: ddTlist){
                    string csvRowVal =  ddt.Requesttype__c+','
                        +ddt.DirectDebitRequest__r.CustomerAccountName__c+','
                        +ddt.DirectDebitRequest__r.CustomerBankName__c+','
                        +ddt.DirectDebitRequest__r.PayerIdentification__c+','
                        +ddt.DDBank__c +','
                        +ddt.DirectDebitRequest__r.Name+','
                        +ddt.RequestFileName__c+','
                        +ddt.TransactionStatus__c+','
                        +ddt.DirectDebitRequest__r.SentTobankDate__c ;
                    csvRowValues.add(csvRowVal);
                }
                DateTime dt = Datetime.now();
                String strTimezone = dt.format('MMMMM dd, yyyy');
                csvColumnHeader = 'Request Type,Customer AccountName,Customer BankName,Payer Identification,Direct Debit Bank,Aldar DD Number,Request File Name,Status, Finance Sent to Bank date \n';
                String csvFile = csvColumnHeader + String.join(csvRowValues,'\n');
                String fileName = bankName+'_Aldar_PendingDD_'+strTimezone;
                //=='Abu Dhabi Commercial Bank' ? 'ADCB_DDR_SentToBank.pdf' : 'FAB_DDR_SentToBank.pdf';
               
                Integer ackCount = 0;
                Integer sentToCount =0;
                Integer collectionackCount = 0;
                Integer collectionsentToCount = 0;
                Integer cancellationackCount = 0;
                Integer cancellationsentCount = 0;
                
                if(statusDDtransactionMap.get(bankName) != null){
                    ackCount=  stDDTMap.get('ACK') != null ? stDDTMap.get('ACK').size():0;
                    sentToCount= stDDTMap.get('Sent to Bank') != null ?stDDTMap.get('Sent to Bank').size() :0;
                }
                                
                if(CollectionstatusDDtransactionMap.get(bankName) != null){
                    collectionackCount = CollectionstDDTMap.get('ACK') != null ? CollectionstDDTMap.get('ACK').size():0;
                    collectionsentToCount = CollectionstDDTMap.get('Sent to Bank') != null ?CollectionstDDTMap.get('Sent to Bank').size() :0;
                }
                
                if(CancellationstatusDDtransactionMap.get(bankName) != null){
                    cancellationackCount = CancellationDDTMap.get('ACK') != null ? CancellationDDTMap.get('ACK').size():0;
                    cancellationsentCount = CancellationDDTMap.get('Sent to Bank') != null ?CancellationDDTMap.get('Sent to Bank').size() :0;
                }
                
                Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
                attach.setFileName(fileName+'.csv');
                attach.setInline(false);
                attach.Body =Blob.valueOf(csvFile);
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setUseSignature(false);
                if(owea != null){
                   mail.setOrgWideEmailAddressId(owea.Id);
                }
                mail.setToAddresses(emailMap.get(bankName));
                mail.setSubject('Aldar -'+bankName+' Pending Direct Debit Registrations/Collections '+strTimezone);
                mail.setHtmlBody('Dear <b>'+bankName+'</b> Team, <br/><br/>'+System.Label.DDRNotificationToBankEmailBody+' <br/><br/><b> Summary:</b> <br/><br/>  Total Registration pending DD: '+(ackCount+sentToCount)+' <br/> Total Registration ACK received: '+ackCount+ ' <br/> Total Registration sent to bank: '+ sentToCount+'</b> <br/><br/>  Total Collection pending DD: '+(collectionackCount+collectionsentToCount) +' <br/> Total Collection ACK received: '+collectionackCount+ ' <br/> Total Collection sent to bank: '+ collectionsentToCount+'</b> <br/><br/> Total Cancellation pending DD: '+(cancellationackCount+cancellationsentCount) +' <br/> Total Cancellation ACK received: '+cancellationackCount+ ' <br/> Total Cancellation sent to bank: '+cancellationsentCount+' <br/><br/><br/> Thanks, <br/> Aldar Team');
                mail.setFileAttachments(new Messaging.EmailFileAttachment[] { attach }); 
                mails.add(mail);
              
               // ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Email with PDF sent to '+emailList));
            }   
             Messaging.sendEmail(mails);
        }catch(Exception ex){
            LoggerService.save(LoggerService.addApexLog(ex,'DDRNotificationToBankPDFHandler','sendcsv',''));
        } 
    }
}