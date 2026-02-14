import { LightningElement ,wire, api} from 'lwc';
import sendDemandLetter from '@salesforce/apex/DefaultAndTerminationUtility.sendFormalDemandLetter';	
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { CloseActionScreenEvent } from "lightning/actions";
export default class LwcSendFormalDefaultNotice extends NavigationMixin(LightningElement) {
@api recordId;
@api helpText = 'Please wait while loading…';

@api size = 'medium';

@api variant = 'base';


@api showSpinner = false;
@wire(CurrentPageReference)
getStateParameters(currentPageReference) {
    if (currentPageReference) {
        this.recordId = currentPageReference.state.recordId;
    }
    console.log('Load recordId::'+this.recordId);
}
connectedCallback(){
    console.log('recordId::'+this.recordId);
    this.showSpinner = true;
    sendDemandLetter({srId:this.recordId})
    .then(result=>{
      
            const event = new ShowToastEvent({
                title: 'Success',
                message: 'Email Send Successfully!',
                variant: 'success',
                mode: 'dismissable'
            });
            this.dispatchEvent(event);
            this.dispatchEvent(new CloseActionScreenEvent());
        
        this.showSpinner = false;
    })
    .catch(error=>{
        this.showSpinner = false;
            const event = new ShowToastEvent({
                title: 'Error',
                message: 'Error! Occured',
                variant: 'error',
                mode: 'dismissable'
            });
            this.dispatchEvent(event);
        
        console.log('Error:'+JSON.stringify(error));
        this.dispatchEvent(new CloseActionScreenEvent());
    
    })
}
}