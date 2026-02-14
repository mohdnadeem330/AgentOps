public class SalesCommissionEmailController {
    
    public String  strMonth {set; get;}
    public String  strYear {set; get;}
    public String  strmonthluSalesTargetId {set; get;}
    
    public SalesCommissionEmailController(){
        system.debug('parentMonthlySalesTargetId>>>>>'+strmonthluSalesTargetId);
    }
    
    Public List<MonthlySalesTarget__c> monthlySalesTargetList{
       get {
            List<String> managerRoles = new List<String>{'Sales Manager - AUH','Sales Manager - DXB','Sales Manager - Land','Sales Manager - VIP','CASA - Sales Manager'};
       return [SELECT Name, TargetAmount__c, InventoryCommission__c,TotalPayableCommission__c,ResourceRole__c,
                                     ResourceName__r.Name
                                     FROM MonthlySalesTarget__c 
                                     where 
                                    ResourceRole__c IN: managerRoles AND MonthlySalesTarget__c=:this.strmonthluSalesTargetId
                                    AND TargetMonth__c=:strMonth AND TargetYear__c=:strYear];
    }
    private set; 
    }
    
    Public List<MonthlySalesTarget__c> headsData{
       get {
           List<String>  managerandHeadsRoles = new List<String>{'Head of Sales - AUH','Head of Sales - CASA','Head of Sales - DXB','Head of Sales - Land','Head of Sales - VIP'};
       return [SELECT Name, TargetAmount__c, InventoryCommission__c,TotalPayableCommission__c,ResourceRole__c,
                                     ResourceName__r.Name,ResourceName__r.Team__c
                                     FROM MonthlySalesTarget__c 
                                     where ResourceRole__c IN: managerandHeadsRoles AND MonthlySalesTarget__c=:this.strmonthluSalesTargetId
                                    AND TargetMonth__c=:strMonth AND TargetYear__c=:strYear];
    }
    private set; 
    }
    
    Public List<MonthlySalesTarget__c> directorsData{
       get {
           List<String>  directorRoles = new List<String>{'Associate Director of Sales'};
       return [SELECT Name, TargetAmount__c, InventoryCommission__c,TotalPayableCommission__c,ResourceRole__c,
                                     ResourceName__r.Name
                                     FROM MonthlySalesTarget__c 
                                     where ResourceRole__c IN: directorRoles AND MonthlySalesTarget__c=:this.strmonthluSalesTargetId
              AND TargetMonth__c=:strMonth AND TargetYear__c=:strYear];
    }
    private set; 
    }
    
    Public List<MonthlySalesTarget__c> leaderShip{
       get {
           List<String>  leaderShipRoles = new List<String>{'Executive Director of Sales','CCO'};
       return [SELECT Name, TargetAmount__c, InventoryCommission__c,TotalPayableCommission__c,ResourceRole__c,
                                     ResourceName__r.Name
                                     FROM MonthlySalesTarget__c 
                                     where ResourceRole__c IN: leaderShipRoles AND MonthlySalesTarget__c=:this.strmonthluSalesTargetId
              AND TargetMonth__c=:strMonth AND TargetYear__c=:strYear];
    }
    private set; 
    }
    
     
    
}