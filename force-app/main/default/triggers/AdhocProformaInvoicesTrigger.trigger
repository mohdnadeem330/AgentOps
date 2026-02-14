trigger AdhocProformaInvoicesTrigger on Adhoc_Proforma_Invoices__c (before insert,before update,after insert) {
    try {
        new AdhocProformaInvoicesHandler().run('Adhoc_Proforma_Invoices__c');} catch(Exception e) { LoggerService.save(LoggerService.createApexLog(e,'AdhocProformaInvoicesTrigger','AdhocProformaInvoicesTrigger',''));throw e;
    }  
}