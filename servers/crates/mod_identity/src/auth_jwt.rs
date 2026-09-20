use jsonwebtoken::{decode, DecodingKey, Validation};
use serde::Deserialize;

use c35_wire::{WireErr, WireResult};

#[derive(Debug, Deserialize)]
pub struct JwtClaims {
    pub sub: String,
    pub exp: i64,
    #[serde(default)]
    pub iid: i64,
}

pub fn jwt_decode(token: &str, secret: &str) -> WireResult<JwtClaims> {
    let mut validation = Validation::default();
    validation.validate_exp = true;
    let data = decode::<JwtClaims>(
        token,
        &DecodingKey::from_secret(secret.as_bytes()),
        &validation,
    )
    .map_err(|_| WireErr::Unauthorized)?;
    Ok(data.claims)
}

pub fn jwt_caller_iid(claims: &JwtClaims) -> WireResult<i64> {
    if claims.iid != 0 {
        return Ok(claims.iid);
    }
    claims
        .sub
        .parse::<i64>()
        .map_err(|_| WireErr::Unauthorized)
}
