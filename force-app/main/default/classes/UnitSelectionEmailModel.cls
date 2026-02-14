/*
* Purpose: Construct a Unit Selected Email Detail Modal to store information about the chosen unit for the Email Template..
*/
public class UnitSelectionEmailModel {
    public String unitName                      {set;get;}
    public String unitArea                      {set;get;}
    public String currencyIsoCode               {set;get;}
    public Decimal netAmount                    {set;get;}
    public Decimal totalInstallmentReceived     {set;get;}
    public Decimal totalOutstanding             {set;get;}
    public String equity                        {set;get;}
    public String paymentPlan                   {set;get;}
    public String optionSelected                {set;get;}
    public Decimal lossCalculation              {set;get;}
    public Decimal equityRefund                 {set;get;}
    public Decimal cancelledUnitEquity          {set;get;}
    public Decimal aldarLoss                    {set;get;}
    public Decimal equityShifted                {set;get;}
    public Decimal balanceAfterEquityShifted    {set;get;}
    
    public UnitSelectionEmailModel() {}
    public UnitSelectionEmailModel(SRUnitSelected__c srUnitSelected) {
        this.unitName = srUnitSelected.SalesOrder__r.Unit__r.Name;
        this.unitArea = String.valueOf(srUnitSelected.SalesOrder__r.Unit__r.TotalArea__c);
        this.currencyIsoCode = srUnitSelected.CurrencyIsoCode;
        this.netAmount = srUnitSelected.SalesOrder__r.NetAmount__c;
        this.totalInstallmentReceived = srUnitSelected.SalesOrder__r.TotalBilled__c;
        this.totalOutstanding = srUnitSelected.SalesOrder__r.TotalOutstanding__c;
        this.equity = String.valueOf(srUnitSelected.Equity__c);
        this.paymentPlan = srUnitSelected.SalesOrder__r.PaymentPlan__r.Name;
        this.optionSelected = srUnitSelected.OptionSelected__c;
        this.lossCalculation = srUnitSelected.FinalLossCalculation__c;
        this.equityRefund = srUnitSelected.FinalEquityRefund__c;
    }
}