import Images from "@salesforce/resourceUrl/RETLTenantPortalImages";
import { LightningElement, api, track } from 'lwc';
export default class Retl_TenantConfirmationScreen extends LightningElement {
    // ---- Static resources
    successimage = `${Images}/Request/success.png`
    icon9image = `${Images}/Request/icon9.png`
    icon1image = `${Images}/Request/icon1.png`
    icon8image = `${Images}/Request/icon8.png`
    icon12 = `${Images}/Request/icon12.png`
    icon1 = `${Images}/Request/icon1.png`
    icon2 = `${Images}/Request/icon2.png`
    icon3 = `${Images}/Request/icon3.png`
    icon4 = `${Images}/Request/icon4.png`
    icon5 = `${Images}/Request/icon5.png`
    icon6 = `${Images}/Request/icon6.png`
    icon7 = `${Images}/Request/icon7.png`
    icon8 = `${Images}/Request/icon8.png`
    icon21 = `${Images}/Request/icon21.png`
    icon18 = `${Images}/Request/icon18.png`

    @api selectedStore;
    @api selectedServiceType;
    @api selectedSubCategory;
    @api caseId;
    @api caseNumber;
    @api selectedCategory;
    @api subject
    @api description
    @track additionalAttachments = [];
    @track serviceAccordion = [];
    @track isAllowComment = true;
    @track contractorSections = [];
    showLine;
    additionalInfo;

     // ---- UI helpers
    get isNOCWP() { return ['NOC', 'Work Permit'].includes(this.selectedCategory); }
    get isNOC() { return this.selectedCategory === 'NOC'; }
    get isWorkPermit() { return this.selectedCategory === 'Work Permit'; }
    get isGeneral() { return this.selectedCategory === 'General Request'; }
    get titleContent() {
        return this.isNOC ? 'NOC Request'
            : this.isGeneral ? this.selectedServiceType
                : '';
    }

    connectedCallback() {
        console.log('CONFIRM: connectedCallback fired with props:', {
            caseId: this.caseId,
            selectedCategory: this.selectedCategory,
            selectedSubCategory: this.selectedSubCategory,
            selectedServiceType: this.selectedServiceType
        });

        //Promise.resolve().then(() => this.getCase());
    }


    handleDone() {
        console.log('CONFIRM: Done button clicked – dispatching redirect event');
        this.dispatchEvent(new CustomEvent('redirect', {
            detail: { redirect: true },
            bubbles: true,
            composed: true
        }));
    }
}