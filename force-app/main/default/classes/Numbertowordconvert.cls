public class Numbertowordconvert {
    public Decimal totalAmount { get; set; }
    public Decimal fivePercent { get; set; }
    public String totalAmountInWords { get; set; }
    public String recordId { get; set; }
    
    public NumberToWordConvert(ApexPages.StandardController controller) {
        Payment_Request__c paymentRequest = (Payment_Request__c)controller.getRecord();
        recordId = ApexPages.currentPage().getParameters().get('id');
        system.debug('record'+paymentRequest.Amount__c);
        system.debug('record'+paymentRequest.Amount_Exclusive_VAT__c);
        totalAmount = paymentRequest.Amount__c;
        System.debug('Total Amount'+ totalAmount);
        fivePercent = totalAmount * 0.05;
        totalAmountInWords = NumberToWordConvert.convertNumberToWords(totalAmount);
    }
    
    private static String convertNumberToWords(Decimal num) {
        if (num == null) {
            return '';
        }
        
        // Define arrays for various number representations
        String[] units = new String[]{'', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine'};
            String[] teens = new String[]{'', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen'};
                String[] tens = new String[]{'', 'Ten', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'};
                    String[] thousands = new String[]{'', 'Thousand', 'Million', 'Billion', 'Trillion', 'Quadrillion', 'Quintillion'};
                        
                        // Convert the number to words
                        String result = '';
        String result1 = '';
        String result2 = '';
        integer decimal1=0;
        
        
        Integer numInt = num.intValue();
        integer decimalPart = (integer)math.abs((num-numInt)*100);
        decimal1=decimalPart;
        
        system.debug('Decimal'+decimalPart);
        for (Integer i = 0; numInt > 0; i++) {
            if (Math.mod(numInt, 1000) != 0) {
                System.debug('mod '+Math.mod(numInt, 1000));
                result1 = convertNumberToWordsHelper(Math.mod(numInt, 1000), units, teens, tens) + thousands[i] + ' ' + result1;
                System.debug('result1 '+result1); 
                
                
            }
            numInt /= 1000;
        }
        
        for (Integer i = 0; decimalPart > 0; i++) {
            if (Math.mod(decimalPart, 1000) != 0) {
                System.debug('mod1 '+Math.mod(decimalPart, 1000));
                result2 = convertNumberToWordsHelper(Math.mod(decimalPart, 1000), units, teens, tens) + thousands[i] + ' ' + result2;
                System.debug('result2 '+result2); 
                
                
            }
            decimalPart /= 1000;
        }
        result=result1+' Dirhams ';
        if(decimal1 > 0){
            result+='And '+result2+' Fils ';
        }
        
        return result.trim();
    }
    
    private static String convertNumberToWordsHelper(Integer num, String[] units, String[] teens, String[] tens) {
        String result = '';
        if (num >= 100) {
            result += units[num / 100] + ' Hundred  ';
            num = Math.mod(num, 100);
        }
        if (num >= 11 && num <= 19) {
            result += teens[num - 10] + ' ';
        } else if (num >= 20 || num == 10) {
            result += tens[num / 10] + ' ';
            System.debug('result1 '+result);
            
            num = Math.mod(num, 10); //changed 100 to 10
            System.debug('result2 '+num);
            if(num>20 && num<=99 ){
                result += units[num] + ' ';    
            }
        }
        if (num >= 1 && num <= 9) {
            result += units[num] + ' ';
        }
        System.debug('Final '+result);
        return result;
    }
     public PageReference save() {
        Blob pdfBlob;
        // Render the VF page as a PDF
        PageReference pdfPage = Page.DCTaxinvoice; // Replace 'YourVFPageName' with your VF page name
        pdfPage.getParameters().put('id', recordId);
             if(Test.isRunningTest()){
            pdfBlob = blob.valueOf('Unit.Test');
        }else{
        pdfBlob = pdfPage.getContentAsPDF();
        }

        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = 'DCTInvoice';
        contentVersion.PathOnClient = 'DCTInvoice.pdf';
        contentVersion.VersionData = pdfBlob;
        contentVersion.IsMajorVersion = true;
        insert contentVersion;

        // Retrieve the ContentDocumentId
        ContentDocumentLink contentDocumentLink = new ContentDocumentLink(
            ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id].ContentDocumentId,
            LinkedEntityId = recordId,
            ShareType = 'V' 
        );
        insert contentDocumentLink;
         PageReference closePage = new PageReference('/'+recordId); // Replace with your actual VF page
        return closePage;

        
    }
}