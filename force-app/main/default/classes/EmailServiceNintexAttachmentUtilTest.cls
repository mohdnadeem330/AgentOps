@istest
public class EmailServiceNintexAttachmentUtilTest {
    
   static testMethod void TestinBoundEmail()
   
   {
      // Create Test record.
      Account acc = TestObjectsFactory.getPersonAccountRecord();
      insert acc;
      
      Messaging.InboundEmail email = new Messaging.InboundEmail() ;
      Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
      
      List<Messaging.InboundEmail.Header> headersList = new List<Messaging.InboundEmail.Header>();
      Messaging.InboundEmail.Header ibheader = new Messaging.InboundEmail.Header();
      ibheader.name = 'X-SFDC-EntityId';
      ibheader.value = acc.Id;
      headersList.add(ibheader);
      // intialize the list string to store emails.
      List<string> emails = new List<string>{'emailservicenintexattachmentutil@test.com'};
      env.toAddress = 'emailservicenintexattachmentutil@test.com';
      email.headers = headersList;
      email.subject = 'Create case';
      email.fromAddress = 'someaddress@email.com';
      email.fromname = 'testEmail';
      //assigning the emails to toAddresses 
      email.toAddresses = emails;
      email.plainTextBody = 'email body';
      Messaging.InboundEmail.BinaryAttachment attachment = new Messaging.InboundEmail.BinaryAttachment();
      attachment.body = blob.valueOf('my attachment text');
      attachment.fileName = 'textfileone.txt';
      attachment.mimeTypeSubType = 'text/plain';
      email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { attachment };
      Messaging.inboundEmail.TextAttachment textAttachment = new Messaging.inboundEmail.TextAttachment();
      textAttachment.body = 'my attachment text';
      textAttachment.fileName = 'textfileone.txt';
      textAttachment.mimeTypeSubType = 'text/plain';
      email.TextAttachments = new Messaging.inboundEmail.TextAttachment[] { textAttachment };
     
      EmailServiceNintexAttachmentUtil  testInbound = new EmailServiceNintexAttachmentUtil ();
      testInbound.handleInboundEmail(email, env);
   }
}