import { LightningElement, track, api } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import MY_STYLES from '@salesforce/resourceUrl/RETLLightningOutStyle3';
export default class RetlTenantServiceSelectorLandingPage extends LightningElement {
    @api storeName
    @api orderId;
    @api contactId;
    @api accessToken;
    @api profileName;
    @api userData;
    @api requestSubmittingBy
    connectedCallback() {
        loadStyle(this, MY_STYLES)
            .then(() => {
                console.log('Styles loaded successfully');
            })
            .catch(error => {
                console.error('Error loading styles', error);
            });
        console.log('userData LP', JSON.stringify(this.userData))
    }
}