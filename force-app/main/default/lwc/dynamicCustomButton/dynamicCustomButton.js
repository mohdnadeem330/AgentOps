import { LightningElement ,track,api,wire} from 'lwc';
import getVFDomainURL from "@salesforce/apex/Utilities.getVFDomainURL";
import getReceiptDetails from "@salesforce/apex/ReceiptNOCController.getReceiptDetails";
import sendReceiptstoCustomers from  "@salesforce/apex/SendEmailController.sendReceiptstoCustomers";
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import hasPermissionToSendReceipts from '@salesforce/customPermission/ViewReceiptDetails';


export default class DynamicCustomButton extends NavigationMixin(LightningElement)  {

    @api recordId;
    @track clickedButtonLabel = 'Receipt Advice';
    @track showiframe = false ;
    @track fullUrl ;
    @track nocApplicable ;
    @track showReceipt =false;
    @track showConfirmationPopUp =false;
    @track fullUrl;
    @track isLoading=false;
    @track sendAcknowledgementReceipt = false;
    @track sendAdviceReceipt = false;
    @track popupHeader;
    @track popupMessage;
    @track cardTitle = 'Receipt Details';
    @track sendReceiptButton = 'Send Receipt';


    get isViewReceiptVisible() {
        return hasPermissionToSendReceipts;
    }
    connectedCallback(){
        console.log('Sales Order Record - '+this.recordId);
        getReceiptDetails({salesOrderId :this.recordId })
        .then(data => {
            console.log('data ',data);
            this.nocApplicable = data;
        })
    }

   async handleAckViewReceipt(event){
    
    this.showReceipt = true;
    this.sendAcknowledgementReceipt = true;
    this.sendAdviceReceipt = false;
    this.cardTitle = 'Receipt Acknowledgement Details';
    this.sendReceiptButton = 'Send Receipt Acknowledgement';
      var mainUrl = await getVFDomainURL();
      this.fullUrl = mainUrl + '/apex/ReceiptAcknowledgementDocument?id='+this.recordId;
      console.log('Page URL - '+this.fullUrl);
      
    }

    async handleAdviceViewReceipt(event){
        
        this.showReceipt = true;
        this.sendAcknowledgementReceipt = false;
        this.sendAdviceReceipt = true;
        this.cardTitle = 'Receipt Advice Details';
        this.sendReceiptButton = 'Send Receipt Advice';
        var mainUrl = await getVFDomainURL();
      this.fullUrl = mainUrl + '/apex/ReceiptAdviceDocument?id='+this.recordId;
      console.log('Page URL - '+this.fullUrl);
    }

    sendReceipt(event){
      this.showConfirmationPopUp = true;
      if(this.sendAcknowledgementReceipt){
       this.popupHeader = 'Email Receipt Acknowledgement';
       this.popupMessage = 'Are you sure you want to send Receipt Acknowledgement to customer?';
      }else if(this.sendAdviceReceipt){
        this.popupHeader = 'Email Receipt Advice';
        this.popupMessage = 'Are you sure you want to send Receipt Advice to customer?';
      }
    }
    closeModal(event){
        this.showConfirmationPopUp = false;
    }
    sendEmailWithReceipt(event){
        console.log('this.recordId::'+this.recordId);
        this.isLoading = true;
        sendReceiptstoCustomers({recordId :this.recordId,sendAcknowledgementReceipt:this.sendAcknowledgementReceipt, sendAdviceReceipt:this.sendAdviceReceipt })
        .then(data => {
            console.log('success:::'+data);
            this.showConfirmationPopUp = false;
            this.isLoading = false;
            this.showReceipt=false;
            this.fullUrl = '';
            const evt = new ShowToastEvent({
                title: 'Email Confirmation',
                message: 'Email have been sent successfully.',
                variant: 'success',
            });
            this.dispatchEvent(evt);
        })
        .catch(error => {
            this.isLoading = false;
            this.showReceipt=false;
            this.fullUrl = '';
            this.showConfirmationPopUp = false;
            const evt = new ShowToastEvent({
                title: 'Error Sending Confirmation Mail',
                message: 'Email has not been sent, kindly reach out to your administrator',
                variant: 'error',
            });
            this.dispatchEvent(evt);
        });
    }

    handleClick(event) {
        var mainUrl = getVFDomainURL();
        this.fullUrl = mainUrl + '/apex/ReceiptAdviceDocument?id='+this.recordId;
        console.log('Page URL - '+this.fullUrl);
            this[NavigationMixin.GenerateUrl]({
                type: 'standard__webPage',
                attributes: {
                    url: '/apex/ReceiptAdviceDocument?id='+this.recordId
                }
            }).then(url => { window.open(url) });
    }
    
     handleNocClick(event) {
        console.log('_---- ',this.nocApplicable);
        if(this.nocApplicable){
            var mainUrl = getVFDomainURL();
            this.fullUrl = mainUrl + '/apex/ReceiptNOC?id='+this.recordId;
            console.log('Page URL - '+this.fullUrl);
                this[NavigationMixin.GenerateUrl]({
                    type: 'standard__webPage',
                    attributes: {
                        url: '/apex/ReceiptNOC?id='+this.recordId
                    }
                }).then(url => { window.open(url) });
        }else{
            const evt = new ShowToastEvent({
                title: 'error',
                message: 'NOC not applicable',
                variant: 'error',
            });
            this.dispatchEvent(evt);
          //  alert('NOC not applicable');
        }
       
    }

    handleReceiptAknowledgementClick(event) {
        var mainUrl = getVFDomainURL();
        this.fullUrl = mainUrl + '/apex/ReceiptAcknowledgementDocument?id='+this.recordId;
        console.log('Page URL - '+this.fullUrl);
            this[NavigationMixin.GenerateUrl]({
                type: 'standard__webPage',
                attributes: {
                    url: '/apex/ReceiptAcknowledgementDocument?id='+this.recordId
                }
            }).then(url => { window.open(url) });
    }
}