import { LightningElement, api } from 'lwc';

export default class Retl_TenantTermsAndCondition extends LightningElement {
    @api content;
    handleClose() {
        console.log('debug');
        this.dispatchEvent(new CustomEvent('close'));

    }
}