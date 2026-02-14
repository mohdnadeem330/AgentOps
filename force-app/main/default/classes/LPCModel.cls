public class LPCModel {

    //---- Total LPC for the Sales Order
    public Decimal totalLPC             {get;set;}
    //---- Total LPC Waived for the Sales Order
    public Decimal lpcWaivedAmount      {get;set;}
    //---- Total LPC Paid Charges for the Sales Order
    public Decimal lpcPaid              {get;set;}
    //---- Total LPC Paid Charges and LPC Waived for the Sales Order
    public Decimal totalLPCWaivedOrPaid {get;set;}
    //---- Total LPC Due for the Sales Order
    public Decimal totalLPCDue          {get;set;}
    public SalesOrder__c orderDetail    {get;set;}

    public LPCModel(){
        this.totalLPC = 0;
        this.lpcWaivedAmount = 0;
        this.lpcPaid = 0;
        this.totalLPCWaivedOrPaid = 0;
        this.totalLPCDue = 0;
        this.orderDetail = new SalesOrder__c();
    }
    
}