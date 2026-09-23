use c35_proto::{TxData, TxDelivery, TxDeliveryService, TxDeliveryTo, TxPrompt, TxPromo};

pub fn tx_data_to_json(data: &TxData) -> serde_json::Value {
    let prompt = data.prompt.as_ref().map(|p| {
        serde_json::json!({
            "pics": p.pics,
            "desc": p.desc,
        })
    });
    let delivery = data.delivery.as_ref().map(|d| {
        serde_json::json!({
            "obj_id": d.obj_id,
            "contact_id": d.contact_id,
            "user_iid": d.user_iid,
            "state": d.state,
            "to": d.to.as_ref().map(|t| serde_json::json!({
                "name": t.name,
                "phone": t.phone,
                "address": t.address,
                "email": t.email,
            })),
            "service": d.service.as_ref().map(|s| serde_json::json!({
                "name": s.name,
                "tracking_number": s.tracking_number,
                "tracking_url": s.tracking_url,
                "note": s.note,
            })),
        })
    });
    let promos = data.promos.iter().map(|p| {
        serde_json::json!({
            "promo_id": p.promo_id,
            "code": p.code,
            "name": p.name,
            "amount": p.amount,
        })
    }).collect::<Vec<_>>();
    serde_json::json!({
        "proofs": data.proofs,
        "prompt": prompt,
        "delivery": delivery,
        "promos": promos,
    })
}

pub fn tx_data_from_json(v: &serde_json::Value) -> Option<TxData> {
    if v.is_null() {
        return None;
    }
    let proofs = v
        .get("proofs")
        .and_then(|p| p.as_array())
        .map(|a| a.iter().filter_map(|x| x.as_str().map(String::from)).collect())
        .unwrap_or_default();
    let prompt = v.get("prompt").and_then(|p| {
        Some(TxPrompt {
            pics: p
                .get("pics")
                .and_then(|x| x.as_array())
                .map(|a| a.iter().filter_map(|i| i.as_str().map(String::from)).collect())
                .unwrap_or_default(),
            desc: p.get("desc").and_then(|x| x.as_str()).unwrap_or("").into(),
        })
    });
    let delivery = v.get("delivery").and_then(|d| {
        Some(TxDelivery {
            obj_id: d.get("obj_id").and_then(|x| x.as_i64()).unwrap_or(0),
            contact_id: d.get("contact_id").and_then(|x| x.as_i64()).unwrap_or(0),
            user_iid: d.get("user_iid").and_then(|x| x.as_i64()).unwrap_or(0),
            state: d.get("state").and_then(|x| x.as_str()).unwrap_or("").into(),
            to: d.get("to").and_then(|t| {
                Some(TxDeliveryTo {
                    name: t.get("name").and_then(|x| x.as_str()).unwrap_or("").into(),
                    phone: t.get("phone").and_then(|x| x.as_str()).unwrap_or("").into(),
                    address: t.get("address").and_then(|x| x.as_str()).unwrap_or("").into(),
                    email: t.get("email").and_then(|x| x.as_str()).unwrap_or("").into(),
                })
            }),
            service: d.get("service").and_then(|s| {
                Some(TxDeliveryService {
                    name: s.get("name").and_then(|x| x.as_str()).unwrap_or("").into(),
                    tracking_number: s.get("tracking_number").and_then(|x| x.as_str()).unwrap_or("").into(),
                    tracking_url: s.get("tracking_url").and_then(|x| x.as_str()).unwrap_or("").into(),
                    note: s.get("note").and_then(|x| x.as_str()).unwrap_or("").into(),
                })
            }),
        })
    });
    let promos = v
        .get("promos")
        .and_then(|p| p.as_array())
        .map(|a| {
            a.iter()
                .filter_map(|p| {
                    Some(TxPromo {
                        promo_id: p.get("promo_id").and_then(|x| x.as_str()).unwrap_or("").into(),
                        code: p.get("code").and_then(|x| x.as_str()).unwrap_or("").into(),
                        name: p.get("name").and_then(|x| x.as_str()).unwrap_or("").into(),
                        amount: p.get("amount").and_then(|x| x.as_i64()).unwrap_or(0),
                    })
                })
                .collect()
        })
        .unwrap_or_default();
    Some(TxData {
        proofs,
        prompt,
        delivery,
        promos,
    })
}
