import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { FlowNavigationFinishEvent } from 'lightning/flowSupport';


export default class NavToRecord extends NavigationMixin(LightningElement) {
    @api recordId; // The recordId will be passed from the Flow
    @api caseId
    connectedCallback() {
        //code
     
        // Custom navigation logic if needed
             window.location.href = `/${this.recordId}`;
        // Dispatch the Flow Finish event to complete the flow
        // this.dispatchEvent(new FlowNavigationFinishEvent());
    }

    
}