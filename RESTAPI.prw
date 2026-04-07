#Include 'protheus.ch'
#Include 'parmtype.ch'
#Include "RestFul.CH"
#Include "FWMVCDEF.CH"

////============================================================================////
    // Início da criação do serviço REST
////============================================================================////
WSRESTFUL RESTAPI DESCRIPTION "Serviço REST para manipulação de Produtos/SB1"

////=============================================================================////
    // Parâmetro utilizado para busca de produto e para exclusão via método delete.
////=============================================================================////
WSDATA CODPRODUTO AS STRING

////=============================================================================////
    // Início da criação dos métodos que o WebService irá exportar.
    // Primeiro método é do tipo GET, utilizado para buscar um produto a partir do código informado no parâmetro CODPRODUTO.
    // Segundo método é do tipo POST, utilizado para inserir um novo produto utilizando os dados enviados no corpo da requisição.
    // Terceiro método é do tipo PUT, utilizado para atualizar os dados de um produto existente utilizando os dados enviados no corpo da requisição e o código do produto informado no parâmetro CODPRODUTO.
    // Quarto método é do tipo DELETE, utilizado para excluir um produto existente utilizando o código do produto informado no parâmetro CODPRODUTO.
////=============================================================================////
WSMETHOD GET buscarProduto;
DESCRIPTION "Retorna os dados do produto a partir do código informado no parâmetro CODPRODUTO.";
WSSYNTAX "GET /RESTAPI/buscarProduto?CODPRODUTO={CODPRODUTO}";

WSMETHOD POST inserirProduto;
DESCRIPTION "Insere um novo produto utilizando os dados enviados no corpo da requisição.";
WSSYNTAX "POST /RESTAPI/inserirProduto";

WSMETHOD PUT atualizarProduto;
DESCRIPTION "Atualiza os dados de um produto existente utilizando os dados enviados no corpo da requisição e o código do produto informado no parâmetro CODPRODUTO.";
WSSYNTAX "PUT /RESTAPI/atualizarProduto?CODPRODUTO={CODPRODUTO}";

WSMETHOD DELETE excluirProduto;
DESCRIPTION "Exclui um produto existente utilizando o código do produto informado no parâmetro CODPRODUTO.";
WSSYNTAX "DELETE /RESTAPI/excluirProduto?CODPRODUTO={CODPRODUTO}";

////============================================================================////
    // Fim da criação do serviço REST
////============================================================================////
END WSRESTFUL

//-------------------------------------------------------------------
/*/{Protheus.doc} WSMETHOD buscarProduto
@description Lógica para buscar o produto a partir do código informado no parâmetro CODPRODUTO. Aqui você pode implementar a lógica para acessar o banco de dados e retornar os dados do produto.
@author  Bruno de Souza
@since   07/04/2026
@version v1.0
@syntax  GET /RESTAPI/buscarProduto?CODPRODUTO={CODPRODUTO}
/*/
//-------------------------------------------------------------------

WSMETHOD GET buscarProduto WSSERVICE RESTAPI
    // Lógica para buscar o produto a partir do código informado no parâmetro CODPRODUTO.
    // Aqui você pode implementar a lógica para acessar o banco de dados e retornar os dados do produto.
    Local aArea      := FWGetArea()
    //Local lPrepEnv   := .F.
    Local lRet      := .T.
    Local lRpcEnv   := .F.
    Local cStatus   := ""
    Local cCodProd  := AllTrim(::CODPRODUTO)
    Local aProd     := {}
    Local oReturn  := JsonObject():New()
    //local cReturn   := ""
    Local oJson     := JsonObject():New()
    Local cJson     := ""
    Local cAliasQry := GetNextAlias()+cValToChar(Randomize(1,999))
    Local cQuery     := ""


    Self:SetContentType("application/json")
    cJson := Self:GetContent()

    MemoWrite("\logs\RESTAPI\entrada_raw.txt", cCodProd)
    ConOut("RESTAPI.buscarProduto - CODPRODUTO: " + cCodProd)

    Conout(" ")
    Conout("WSRESTFUL -> cJson - GET: " + cCodProd)
    Conout(" ")

    FWMakedir("\logs\RESTAPI\GET\")

    Begin Sequence

        ////============================================================================////
            // Abre ambiente no contexto da própria request
        ////============================================================================////
        If Type("cEmpAnt") == "U" .Or. Type("cFilAnt") == "U"
            RpcClearEnv()
            ////============================================================================////
            // Ajuste empresa/filial/usuário conforme seu ambiente
            ////============================================================================////
            RpcSetEnv("99","01")
            lRpcEnv := .T.
        EndIf


        ////============================================================================////
            // Consulta SQL para buscar os dados do produto a partir do código informado.
        ////============================================================================////
        cQuery := " SELECT SB1.B1_COD, SB1.B1_DESC, SB1.B1_MSBLQL, SB1.B1_UM, SB1.B1_TIPO, " + ;
                  "        SB1.B1_GRUPO, SBM.BM_DESC " + ;
                  " FROM " + RetSqlName("SB1") + " SB1 " + ;
                  " LEFT JOIN " + RetSqlName("SBM") + " SBM " + ;
                  "   ON SBM.D_E_L_E_T_ = ' ' " + ;
                  "  AND SBM.BM_FILIAL = '" + xFilial("SBM") + "' " + ;
                  "  AND SBM.BM_GRUPO  = SB1.B1_GRUPO " + ;
                  " WHERE SB1.D_E_L_E_T_ = ' ' " + ;
                  "   AND SB1.B1_FILIAL = '" + xFilial("SB1") + "' " + ;
                  "   AND SB1.B1_COD = '" + cCodProd + "' "

        MemoWrite("\logs\RESTAPI\GET\restapi-get.sql",cQuery)

        DbUseArea(.T., "TOPCONN", TcGenQry(,, cQuery), cAliasQry, .F., .T.)

        If (cAliasQry)->(!Eof())
            If (cAliasQry)->B1_COD == cCodProd
                lRet := .T.
                cStatus     := Iif((cAliasQry)->B1_MSBLQL == "1", "Bloqueado", "Desbloqueado")

                ////============================================================================////
                    // Monta o array de produtos para retornar no JSON
                ////============================================================================////
                Aadd(aProd, JsonObject():New())
                aProd[1]['CodigoProduto']         := AllTrim((cAliasQry)->B1_COD)
                aProd[1]['Descricao']        := AllTrim((cAliasQry)->B1_DESC)
                aProd[1]['Unidade']     := AllTrim((cAliasQry)->B1_UM)
                aProd[1]['Tipo']        := AllTrim((cAliasQry)->B1_TIPO)
                aProd[1]['Grupo']       := AllTrim((cAliasQry)->B1_GRUPO)
                aProd[1]['Status']      := Iif((cAliasQry)->B1_MSBLQL == "1", "Bloqueado", "Desbloqueado")


                oReturn["cRet"]      := "200"
                oReturn["cMessage"]  := "Produto encontrado com sucesso."
                oReturn["produtos"]  := aProd

                Self:SetContentType("application/json")
                Self:SetResponse(FwJsonSerialize(oReturn))
            Else
                lRet := .F.
                SetRestFaultResponse(404, EncodeUTF8("Produto não encontrado."))
            EndIf
        Else
            lRet := .F.
            SetRestFaultResponse(404, EncodeUTF8("Produto não encontrado."))
        EndIf

    End Sequence

    If Select(cAliasQry) > 0
        (cAliasQry)->(DbCloseArea())
    EndIf

    If lRpcEnv
        RpcClearEnv()
    EndIf

    FWRestArea(aArea)
    
    FreeObj(oJson)
    FreeObj(oReturn)

Return lRet


//-------------------------------------------------------------------
/*/{Protheus.doc} WSMETHOD excluirProduto
@description Lógica para excluir um produto existente utilizando o código do produto informado no parâmetro CODPRODUTO. Aqui você pode implementar a lógica para acessar o banco de dados e excluir o produto.
@author  Bruno de Souza
@since   07/04/2026
@version v1.0
@syntax  DELETE /RESTAPI/excluirProduto?CODPRODUTO={CODPRODUTO}
/*/
//-------------------------------------------------------------------
WSMETHOD DELETE excluirProduto WSSERVICE RESTAPI
    // Lógica para excluir um produto existente utilizando o código do produto informado no parâmetro CODPRODUTO.
    // Aqui você pode implementar a lógica para acessar o banco de dados e excluir o produto.
    Local aArea         := FWGetArea()
    Local lRet          := .T.
    Local lRpcEnv       := .F.
    Local cCodProd      := AllTrim(::CODPRODUTO)
    Local cAliasQry     := GetNextAlias()+cValToChar(Randomize(1,999))
    Local cQuery        := ""
    Local oReturn       := JsonObject():New()
    Local cJson         := ""
    Local aProd         := {}
    Local nRecno        := 0


    Self:SetContentType("application/json; charset=utf-8")
    cJson   := Self:GetContent()

    MemoWrite("\logs\RESTAPI\DELETE\entrada_raw.txt", cJson)
    ConOut("RESTAPI.excluirProduto - CODPRODUTO: " + cCodProd)

    Conout(" ")
    Conout("WSRESTFUL -> DELETE: " + cCodProd)
    Conout(" ")

    FWMakedir("\logs\RESTAPI\DELETE\")

    Begin Sequence

        ////============================================================================////
            // Abre ambiente no contexto da própria request
        ////============================================================================////
        If Type("cEmpAnt") == "U" .Or. Type("cFilAnt") == "U"
            RpcClearEnv()
            RpcSetEnv("99","01")
            lRpcEnv := .T.
        EndIf

        ////============================================================================////
            // Consulta SQL para verificar se o produto existe antes de tentar excluir.
        ////============================================================================////
        cQuery := " SELECT R_E_C_N_O_ AS RECNO, B1_COD, B1_DESC, B1_UM, B1_TIPO, B1_GRUPO, B1_MSBLQL " + ;
                  " FROM " + RetSqlName("SB1") + " " + ;
                  " WHERE D_E_L_E_T_ = ' ' " + ;
                  "   AND B1_FILIAL = '" + xFilial("SB1") + "' " + ;
                  "   AND B1_COD = '" + cCodProd + "' "

        Memowrite("\logs\RESTAPI\DELETE\restapi-delete.sql",cQuery)
        MPSysopenQuery(cQuery, cAliasQry)
        //DbUseArea(.T., "TOPCONN", TcGenQry(,, cQuery), cAliasQry, .F., .T.)

        If (cAliasQry)->(!Eof())

            If Select("SB1") == 0
                DbUseArea(.T., "TOPCONN", RetSqlName("SB1"), "SB1", .F., .F.)
            EndIf
           
            ////============================================================================////
                // Produto existe, pode excluir.
            ////============================================================================////

            (cAliasQry)->(DbGoTop())

            If (cAliasQry)->B1_COD == cCodProd
                lRet := .T.
                nRecno := (cAliasQry)->RECNO
            
    
                Aadd(aProd, JsonObject():New())
                aProd[1]['CodigoProduto']           := AllTrim((cAliasQry)->B1_COD)
                aProd[1]['Descricao']               := AllTrim((cAliasQry)->B1_DESC)
                aProd[1]['Unidade']                 := AllTrim((cAliasQry)->B1_UM)
                aProd[1]['Tipo']                    := AllTrim((cAliasQry)->B1_TIPO)
                aProd[1]['Grupo']                   := AllTrim((cAliasQry)->B1_GRUPO)
                aProd[1]['Status']                  := Iif((cAliasQry)->B1_MSBLQL == "1", "Bloqueado", "Desbloqueado")

                DBSelectArea("SB1")
                SB1->(DbGoTo(nRecno))

                If RecLock("SB1", .F.)
                    SB1->(DbDelete())
                    SB1->(MsUnlock())
                    DBCommit()
                Else
                    lRet := .F.
                    SetRestFaultResponse(500, EncodeUTF8("Nao foi possivel obter lock na SB1 para exclusao."))
                EndIf

                If lRet
                    oReturn["cRet"]      := "200"
                    oReturn["cMessage"]  := "Produto excluído com sucesso."
                    oReturn["produtos"]  := aProd

                    Self:SetContentType("application/json")
                    Self:SetResponse(EncodeUTF8(FwJsonSerialize(oReturn)))
                EndIf
            Else
                lRet := .F.
                SetRestFaultResponse(404, EncodeUTF8("Código do produto encontrado na query, não condiz com o corpo da solicitação."))
            EndIf
        Else
            lRet := .F.
            SetRestFaultResponse(404, EncodeUTF8("Produto não encontrado."))
        EndIf

    End Sequence

    If Select(cAliasQry) > 0
        (cAliasQry)->(DbCloseArea())
    EndIf

    If Select("SB1") > 0
        SB1->(DbCloseArea())
    EndIf

    If lRpcEnv
        RpcClearEnv()
    EndIf

    FWRestArea(aArea)

    FreeObj(oReturn)

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} WSMETHOD inserirProduto
@description Lógica para inserir um novo produto utilizando os dados enviados no corpo da requisição. Aqui você pode implementar a lógica para acessar o banco de dados e inserir um novo produto.
@author  Bruno de Souza
@since   07/04/2026
@version v1.0
@syntax  POST /RESTAPI/inserirProduto
/*/
//-------------------------------------------------------------------
WSMETHOD POST inserirProduto WSSERVICE RESTAPI
    // Lógica para inserir um novo produto utilizando os dados enviados no corpo da requisição.
    // Aqui você pode implementar a lógica para acessar o banco de dados e inserir um novo produto.

    Local aArea             := FWGetArea()
    Local lRet              := .T.
    Local lRpcEnv           := .F.
    Local oReturn           := JsonObject():New()
    Local oJson             := JsonObject():New()
    Local cJson             := ""
    Local aProd             := {}
    Local xRet              := ""
    
    Local cAliasQry         := GetNextAlias()+cValToChar(Randomize(1,999))
    Local cQuery            := ""

    Self:SetContentType("application/json; charset=utf-8")

    cJson   := Self:GetContent()
    xRet    := oJson:FromJson(cJson)

    MemoWrite("\logs\RESTAPI\entrada_raw.txt", cJson)

    Conout(" ")
    Conout("WSRESTFUL -> POST: " )
    Conout(" ")

    FWMakedir("\logs\RESTAPI\post")
/*
    If Empty(oJson)
        SetRestFaultResponse(400, EncodeUTF8("JSON inválido ou vazio."))
        Return .F.
    EndIf
*/  

    Begin Sequence
        ////============================================================================////
            // Abre ambiente no contexto da própria request
        ////============================================================================////
        If Type("cEmpAnt") == "U" .Or. Type("cFilAnt") == "U"
            RpcClearEnv()
            ////============================================================================////
            // Ajuste empresa/filial/usuário conforme seu ambiente
            ////============================================================================////
            RpcSetEnv("99","01")
            lRpcEnv := .T.
        EndIf 

        ////============================================================================////
            //Montagem de Query para busca de produto para verificar se já existe um produto com o mesmo código antes de inserir.
        ////============================================================================////

        cQuery := "     SELECT * "
        cQuery += "       FROM " + RetSqlName("SB1") + " "
        cQuery += "      WHERE D_E_L_E_T_ = ' ' "
        cQuery += "        AND B1_FILIAL = '" + xFilial("SB1") + "' "
        cQuery += "        AND B1_COD = '" + AllTrim(oJson["CodigoProduto"]) + "' "

        Memowrite("\logs\RESTAPI\post\restapi-post.sql",cQuery)
        MPSysopenQuery(cQuery, cAliasQry)

        If !((cAliasQry)->(!Eof()))

            If Select("SB1") == 0
                DbUseArea(.T., "TOPCONN", RetSqlName("SB1"), "SB1", .F., .F.)
            EndIf

            DBSelectArea("SB1")
            If RecLock("SB1", .T.)
                SB1->B1_COD                         := AllTrim(oJson["CodigoProduto"])
                SB1->B1_DESC                        := AllTrim(oJson["Descricao"])
                SB1->B1_UM                          := AllTrim(oJson["Unidade"])
                SB1->B1_TIPO                        := AllTrim(oJson["Tipo"])
                SB1->B1_GRUPO                       := AllTrim(oJson["Grupo"])
                SB1->B1_MSBLQL                      := AllTrim(oJson["Status"])
                
                SB1->(MsUnlock())
                DBCommit()

                Aadd(aProd, JsonObject():New())
                aProd[1]['CodigoProduto']           := AllTrim(oJson["CodigoProduto"])
                aProd[1]['Descricao']               := AllTrim(oJson["Descricao"])
                aProd[1]['Unidade']                 := AllTrim(oJson["Unidade"])
                aProd[1]['Tipo']                    := AllTrim(oJson["Tipo"])
                aProd[1]['Grupo']                   := AllTrim(oJson["Grupo"])
                aProd[1]['Status']                  := AllTrim(oJson["Status"])

                

                oReturn["cRet"]      := "200"
                oReturn["cMessage"]  := "Produto Incluído com sucesso."
                oReturn["produtos"]  := aProd

                Self:SetContentType("application/json")
                Self:SetResponse(EncodeUTF8(FwJsonSerialize(oReturn)))
            Else
                lRet := .F.
                SetRestFaultResponse(500, EncodeUTF8("Nao foi possivel obter lock na SB1 para inclusao."))
            EndIf
        Else
            lRet := .F.
            SetRestFaultResponse(404, EncodeUTF8("Produto já existe."))
        EndIf
    End Sequence

    If Select(cAliasQry) > 0
        (cAliasQry)->(DbCloseArea())
    EndIf

    If Select("SB1") > 0
        SB1->(DbCloseArea())
    EndIf

    If lRpcEnv
        RpcClearEnv()
    EndIf

    FWRestArea(aArea)

    FreeObj(oJson)
    FreeObj(oReturn)

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} WSMETHOD atualizarProduto
@description Lógica para atualizar os dados de um produto existente utilizando os dados enviados no corpo da requisição e o código do produto informado no parâmetro CODPRODUTO. Aqui você pode implementar a lógica para acessar o banco de dados e atualizar os dados do produto.
@author  Bruno de Souza
@since   07/04/2026
@version v1.0
@syntax  PUT /RESTAPI/atualizarProduto?CODPRODUTO={CODPRODUTO}
/*/
//-------------------------------------------------------------------
WSMETHOD PUT atualizarProduto WSSERVICE RESTAPI
    // Lógica para atualizar os dados de um produto existente utilizando os dados enviados no corpo da requisição e o código do produto informado no parâmetro CODPRODUTO.
    // Aqui você pode implementar a lógica para acessar o banco de dados e atualizar os dados do produto.

    Local lRet              := .T.
    Local aArea             := FWGetArea()
    Local lRpcEnv           := .F.
    Local oReturn           := JsonObject():New()
    Local oJson             := JsonObject():New()
    Local cJson             := ""
    Local xRet              := ""
    Local aProd             := {}
    Local cAliasQry         := GetNextAlias()+cValToChar(Randomize(1,999))
    Local cQuery            := ""
    Local cCodProd          := AllTrim(::CODPRODUTO)
    Local nRecno            := 0

    Self:SetContentType("application/json; charset=utf-8")

    cJson   := Self:GetContent()
    xRet    := oJson:FromJson(cJson)
    
    MemoWrite("\logs\RESTAPI\PUT\entrada_raw.txt", cJson)
    Conout(" ")
    Conout("WSRESTFUL -> PUT: " )
    Conout(" ")
    FWMakedir("\logs\RESTAPI\PUT\")

    Begin Sequence
        ////============================================================================////
            // Abre ambiente no contexto da própria request
        ////============================================================================////
        If Type("cEmpAnt") == "U" .Or. Type("cFilAnt") == "U"
            RpcClearEnv()
            RpcSetEnv("99","01")
            lRpcEnv := .T.
        EndIf 

        ////============================================================================////
            //Montagem de Query para busca de produto para verificar se o produto existe antes de tentar atualizar.
        ////============================================================================////

        cQuery := "     SELECT R_E_C_N_O_ AS RECNO "
        cQuery += "         FROM " + RetSqlName("SB1") + " SB1 "
        cQuery += "     WHERE D_E_L_E_T_ = ' ' "
        cQuery += "        AND SB1.B1_FILIAL = '" + xFilial("SB1") + "' "
        cQuery += "        AND SB1.B1_COD = '" + cCodProd + "' "

        Memowrite("\logs\RESTAPI\PUT\restapi-put.sql",cQuery)
        MPSysopenQuery(cQuery, cAliasQry)

        If (cAliasQry)->(!Eof())
            nRecno := (cAliasQry)->RECNO

            If Select("SB1") == 0
                DbUseArea(.T., "TOPCONN", RetSqlName("SB1"), "SB1", .F., .F.)
            EndIf

            DBSelectArea("SB1")
            SB1->(DbGoTo(nRecno))

            If RecLock("SB1", .F.)
                SB1->B1_COD                            := cCodProd
                SB1->B1_DESC                           := AllTrim(oJson["Descricao"])
                SB1->B1_UM                             := AllTrim(oJson["Unidade"])
                SB1->B1_TIPO                           := AllTrim(oJson["Tipo"])
                SB1->B1_GRUPO                          := AllTrim(oJson["Grupo"])
                SB1->B1_MSBLQL                         := AllTrim(oJson["Status"])

                SB1->(MsUnlock())
                DBCommit()

                Aadd(aProd, JsonObject():New())
                aProd[1]['CodigoProduto']         := cCodProd
                aProd[1]['Descricao']             := AllTrim(oJson["Descricao"])
                aProd[1]['Unidade']               := AllTrim(oJson["Unidade"])
                aProd[1]['Tipo']                  := AllTrim(oJson["Tipo"])
                aProd[1]['Grupo']                 := AllTrim(oJson["Grupo"])
                aProd[1]['Status']                := AllTrim(oJson["Status"])

                oReturn["cRet"]      := "200"
                oReturn["cMessage"]  := "Produto atualizado com sucesso."
                oReturn["produtos"]  := aProd

                Self:SetContentType("application/json")
                Self:SetResponse(EncodeUTF8(FwJsonSerialize(oReturn)))
            Else
                lRet := .F.
                SetRestFaultResponse(500, EncodeUTF8("Nao foi possivel obter lock na SB1 para alteracao."))
            EndIf
        Else
            lRet := .F.
            SetRestFaultResponse(404, EncodeUTF8("Produto não encontrado."))
        EndIf
    End Sequence

    If Select(cAliasQry) > 0
        (cAliasQry)->(DbCloseArea())
    EndIf

    If Select("SB1") > 0
        SB1->(DbCloseArea())
    EndIf

    If lRpcEnv
        RpcClearEnv()
    EndIf

    FWRestArea(aArea)

    FreeObj(oJson)
    FreeObj(oReturn)
Return lRet
