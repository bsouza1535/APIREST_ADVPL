# RESTAPI - Serviço REST de Produtos (SB1)

Este projeto implementa um WebService REST em AdvPL/Protheus para manipulação de produtos na tabela `SB1`.

## Visão Geral

Serviço: `RESTAPI`  
Descrição: manipulação de produtos (consulta, inclusão, alteração e exclusão).

Arquivo principal:
- `RESTAPI.prw`

## Endpoints

### 1. Buscar produto

- Método: `GET`
- Rota: `/RESTAPI/buscarProduto?CODPRODUTO={CODPRODUTO}`
- Objetivo: retorna os dados de um produto pelo código.

Exemplo de resposta (`200`):

```json
{
  "cRet": "200",
  "cMessage": "Produto encontrado com sucesso.",
  "produtos": [
    {
      "CodigoProduto": "000001",
      "Descricao": "PRODUTO TESTE",
      "Unidade": "UN",
      "Tipo": "PA",
      "Grupo": "001",
      "Status": "Desbloqueado"
    }
  ]
}
```

Possível erro:
- `404`: Produto não encontrado.

---

### 2. Inserir produto

- Método: `POST`
- Rota: `/RESTAPI/inserirProduto`
- Objetivo: inclui um novo produto na `SB1`.

Body JSON esperado:

```json
{
  "CodigoProduto": "000001",
  "Descricao": "PRODUTO TESTE",
  "Unidade": "UN",
  "Tipo": "PA",
  "Grupo": "001",
  "Status": "2"
}
```

Exemplo de resposta (`200`):

```json
{
  "cRet": "200",
  "cMessage": "Produto Incluído com sucesso.",
  "produtos": [
    {
      "CodigoProduto": "000001",
      "Descricao": "PRODUTO TESTE",
      "Unidade": "UN",
      "Tipo": "PA",
      "Grupo": "001",
      "Status": "2"
    }
  ]
}
```

Possíveis erros:
- `404`: Produto já existe.
- `500`: Falha ao obter lock para inclusão.

---

### 3. Atualizar produto

- Método: `PUT`
- Rota: `/RESTAPI/atualizarProduto?CODPRODUTO={CODPRODUTO}`
- Objetivo: altera dados de um produto existente.

Body JSON esperado:

```json
{
  "Descricao": "PRODUTO TESTE ALTERADO",
  "Unidade": "UN",
  "Tipo": "PA",
  "Grupo": "001",
  "Status": "2"
}
```

Exemplo de resposta (`200`):

```json
{
  "cRet": "200",
  "cMessage": "Produto atualizado com sucesso.",
  "produtos": [
    {
      "CodigoProduto": "000001",
      "Descricao": "PRODUTO TESTE ALTERADO",
      "Unidade": "UN",
      "Tipo": "PA",
      "Grupo": "001",
      "Status": "2"
    }
  ]
}
```

Possíveis erros:
- `404`: Produto não encontrado.
- `500`: Falha ao obter lock para alteração.

---

### 4. Excluir produto

- Método: `DELETE`
- Rota: `/RESTAPI/excluirProduto?CODPRODUTO={CODPRODUTO}`
- Objetivo: exclui logicamente (delete) um produto existente.

Exemplo de resposta (`200`):

```json
{
  "cRet": "200",
  "cMessage": "Produto excluído com sucesso.",
  "produtos": [
    {
      "CodigoProduto": "000001",
      "Descricao": "PRODUTO TESTE",
      "Unidade": "UN",
      "Tipo": "PA",
      "Grupo": "001",
      "Status": "Desbloqueado"
    }
  ]
}
```

Possíveis erros:
- `404`: Produto não encontrado.
- `500`: Falha ao obter lock para exclusão.

## Observações Técnicas

- O serviço usa `RpcSetEnv("99","01")` quando necessário para abrir ambiente.
- As operações são feitas na tabela `SB1`, com apoio da `SBM` na consulta do GET.
- O código registra logs em caminhos como:
  - `\logs\RESTAPI\GET\`
  - `\logs\RESTAPI\POST\`
  - `\logs\RESTAPI\PUT\`
  - `\logs\RESTAPI\DELETE\`
- O conteúdo é retornado em `application/json`.

## Exemplo rápido com cURL

Buscar produto:

```bash
curl -X GET "http://SEU_HOST:SEU_PORTA/RESTAPI/buscarProduto?CODPRODUTO=000001"
```

Inserir produto:

```bash
curl -X POST "http://SEU_HOST:SEU_PORTA/RESTAPI/inserirProduto" \
  -H "Content-Type: application/json" \
  -d "{\"CodigoProduto\":\"000001\",\"Descricao\":\"PRODUTO TESTE\",\"Unidade\":\"UN\",\"Tipo\":\"PA\",\"Grupo\":\"001\",\"Status\":\"2\"}"
```

## Autor

- Bruno de Souza
