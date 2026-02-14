import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { FlowNavigationFinishEvent } from 'lightning/flowSupport';

export default class ToastInFlow extends LightningElement {
    @api mode;
    @api variant;
    @api message;
    @api title

    connectedCallback() {
        this.handleShowToast();
        this.handoverCloseAction();
    }

    handleShowToast() {
        const toastEvt = new ShowToastEvent({
            title: this.title,
            mode: this.mode,
            variant: this.variant,
            message: this.message
        });
        this.dispatchEvent(toastEvt);
    }

    handoverCloseAction(){
        const navigateNextEvent = new FlowNavigationFinishEvent();
        this.dispatchEvent(navigateNextEvent);
    }
}