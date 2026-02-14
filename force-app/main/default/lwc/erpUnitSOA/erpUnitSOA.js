import { LightningElement ,track,api,wire} from 'lwc';
import getVFDomainURL from "@salesforce/apex/Utilities.getVFDomainURL";
import getERPSOA from "@salesforce/apex/EPRSOAController.getERPSOA";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';


export default class ErpUnitSOA extends LightningElement {
    
    @api recordId;
    @track pdf;
    @track
    fileName = 'SOA.pdf';
    isSpinner=false;
    isERPbtnVisible=true;
  
  handleClick() {
    this.isSpinner=true;
    this.isERPbtnVisible=false;
    getERPSOA({ recordId: this.recordId }).then((result) => {
      console.log('Result ****'+result.soaPDFstr);
      if(result!=null && result.soaPDFstr!=''){
        console.log('Record Id *** '+this.recordId);
        console.log('ERP SOA Response *** '+result);
        let element = document.createElement('a');
        element.setAttribute('href', 'data:application/pdf;base64,' + result.soaPDFstr);
        let pdfNameStr=result.unitNumber+'_ERP_SOA.pdf';
        element.setAttribute('download', pdfNameStr);
        element.style.display = 'block';
        document.body.appendChild(element);
        element.click();
        document.body.removeChild(element);
        this.isSpinner=false;
        this.isERPbtnVisible=true;
      }else{
        this.isSpinner=false;
        this.isERPbtnVisible=true;
        const event = new ShowToastEvent({
          title: 'NO Data',
          message: 'NO EPR SOA data found',
          variant: 'Error',
          mode: 'dismissable'
      });
      this.dispatchEvent(event);
      }
      
    }).catch(error=>{
       console.log('Error Occured while fetching ERP SOA ', error);
       this.isSpinner=false;
        this.isERPbtnVisible=true;
        const event = new ShowToastEvent({
          title: 'Error',
          message: 'Error Occured while calling service',
          variant: 'Error',
          mode: 'dismissable'
      });
      this.dispatchEvent(event);
    })
}

}