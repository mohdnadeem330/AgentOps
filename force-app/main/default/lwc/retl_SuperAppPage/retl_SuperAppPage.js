import { LightningElement, track, wire } from 'lwc';
import images from "@salesforce/resourceUrl/superimages";
import getCurrentUser from '@salesforce/apex/RETL_SuperAppPageController.getCurrentUser';
export default class Retl_SuperAppPage extends LightningElement {
    bgimage = images + '/bgimg.png';
    image1 = images + '/im1.png';
    image2 = images + '/im2.png';
    get backgroundStyle() {
        return `background-image: url(${this.bgimage});`;
    }
    user;
    isRetail = false;
    showSuperApp = false;
    error;
    vertical;


    @wire(getCurrentUser)
    wiredUser({ data, error }) {
        if (data) {
            this.user = data;
            this.vertical = data?.Contact?.Account?.CustomerVertical__c;
            if(this.vertical && this.vertical.includes('Retail') && this.vertical.includes('District Management')){
                this.showSuperApp = true;
            }
            else if(this.vertical && (this.vertical ==='Retail' ||  data.Contact.RecordType.Name ==='Contact')){
                this.handleRetailClick();
            }
            else if(this.vertical && (this.vertical ==='District Management' || data.Contact.RecordType.Name ==='DM_Contact')){
                this.handleDistrictClick();
            }
            else{
                this.showSuperApp = false;
            }

            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.user = undefined;
        }
    }

    handleDistrictClick() {
        this.isRetail = false;
        this.showSuperApp = false;
        window.open('/districtMngmt/', '_self');

    }

    handleRetailClick() {
        this.isRetail = true;
        this.showSuperApp = false;
        window.open('/business/retail', '_self');
    }
}