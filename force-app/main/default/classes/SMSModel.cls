public class SMSModel {

    public String smsMessage    {get;set;}
    public String destination   {get;set;}
    public String recordId      {get;set;}

    public SMSModel(){
        this.smsMessage = '';
        this.destination = '';
        this.recordId = '';
    }
}