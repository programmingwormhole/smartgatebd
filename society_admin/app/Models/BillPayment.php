<?php

namespace App\Models;


use Illuminate\Database\Eloquent\Model;

class BillPayment extends Model
{
    protected $fillable = [
        'bill_id', 'payment_gateway_id', 'amount', 'method',
        'trx_id', 'notes', 'screenshot_path', 'status', 'rejection_reason'
    ];

    public function bill()
    {
        return $this->belongsTo(Bill::class);
    }

    public function gateway()
    {
        return $this->belongsTo(PaymentGateway::class, 'payment_gateway_id');
    }
}
