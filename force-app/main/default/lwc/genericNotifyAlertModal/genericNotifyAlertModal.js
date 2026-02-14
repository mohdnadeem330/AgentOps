import { api, LightningElement } from 'lwc';

export default class GenericNotifyAlertModal extends LightningElement 
{
    @api title="";
    @api body="";
    closeModal() {
        this.dispatchEvent(new CustomEvent('close', { detail: { isOpen: false } }));
    }
}