import { LightningElement, api, track } from 'lwc';
import getOrdersForBrand from '@salesforce/apex/RETL_AccountMetricsController.getOrdersForBrand';
import getLicensesForBrand from '@salesforce/apex/RETL_AccountMetricsController.getLicensesForBrand';
import getOrderCountForBrand from '@salesforce/apex/RETL_AccountMetricsController.getOrderCountForBrand';
import getLicenseCountForBrand from '@salesforce/apex/RETL_AccountMetricsController.getLicenseCountForBrand';
import getBrandName from '@salesforce/apex/RETL_AccountMetricsController.getBrandName';



export default class BrandDashboard extends LightningElement {
    @api recordId;

   @track accountName = '';
    @track allOrders = [];
    @track allLicenses = [];

    @track brandOrdersCount = 0;
    @track licenseLinksCount = 0;

    @track showOrderModal = false;
    @track showLicenseModal = false;


   

    get hasOrders() {
        return this.allOrders && this.allOrders.length > 0;
    }

    get hasLicenses() {
        return this.allLicenses && this.allLicenses.length > 0;
    }

    connectedCallback() {
        this.loadData();
    }

    async loadData() {
        try {
            const [orders, licenses, orderCount, licenseCount,brandName] = await Promise.all([
                getOrdersForBrand({ brandId: this.recordId }),
                getLicensesForBrand({ brandId: this.recordId }),
                getOrderCountForBrand({ brandId: this.recordId }),
                getLicenseCountForBrand({ brandId: this.recordId }),
                getBrandName({ brandId: this.recordId })
            ]);

            this.allOrders = orders.map(order => ({
                key: order.Id,
                ...order,
                recordUrl: '/' + order.Id
            }));

            this.allLicenses = licenses.map(license => ({
                key: license.Id,
                ...license,
                recordUrl: '/' + license.Id,
                brandUrl: license.RETL_Brand__r ? '/' + license.RETL_Brand__r.Id : null,
                customerUrl: license.RETL_Customer__r ? '/' + license.RETL_Customer__r.Id : null
            }));

            this.brandOrdersCount = orderCount;
            this.licenseLinksCount = licenseCount;
             this.accountName = brandName;

        } catch (error) {
            console.error('Error loading brand data:', error);
        }
    }

    openOrderModal() {
        this.showOrderModal = true;
    }

    openLicenseModal() {
        this.allLicenses = [...this.allLicenses];
        this.showLicenseModal = true;
    }

    closeModals() {
        this.showOrderModal = false;
        this.showLicenseModal = false;
        this.allOrders = [...this.allOrders];
        this.allLicenses = [...this.allLicenses];
    }
}