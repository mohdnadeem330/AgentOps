@isTest
public class AdhocProformaInvoicesHandlerTest {

    @isTest
    public static void creattestProformaInvoice ()
    {Adhoc_Proforma_Invoices__c api = new Adhoc_Proforma_Invoices__c();
	api.Amount__c = 123.00;
	api.Name = 'Test Proforma';
	insert api;
    System.debug('Adhoc_Proforma_Invoices ID: ' + api.Id);
    System.debug('Adhoc_Proforma_Invoicest');
}
    
}