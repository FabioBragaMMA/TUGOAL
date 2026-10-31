TUGOAL — Documentação Completa do Projeto

O TUGOAL é uma aplicação móvel de gestão, simulação e acompanhamento estatístico de futebol desenvolvida com a framework Flutter, a linguagem Dart e módulos computacionais em linguagem C. Este documento descreve de forma exaustiva todas as funcionalidades implementadas, a organização detalhada do código fonte por pastas e ficheiros, e as soluções arquiteturais adotadas no âmbito da unidade curricular de Aplicações Móveis (TeSP em Desenvolvimento de Aplicações Móveis, IPCA - Polo de Vila Verde).

Estrutura de Pastas e Distribuição de Componentes

Todo o código de lógica, estado e interface encontra-se estruturado de forma estrita dentro do diretório principal lib/ (com módulos suplementares de cálculo em C), promovendo uma arquitetura limpa, legível e de fácil manutenção. Abaixo encontra-se o mapa detalhado de onde está cada elemento da aplicação:

1. lib/core/ (O Núcleo da Aplicação)

Esta pasta centraliza as configurações globais, utilitários transversais e motores de lógica de negócio que servem toda a aplicação de forma desacoplada.

constants.dart: Centraliza as constantes do sistema, tais como cores da identidade visual, estilos de texto padrão e configurações globais de rota.

providers/: Contém os gestores de estado da aplicação:

auth_provider.dart: Gere a autenticação e os níveis de permissão da aplicação (diferenciando as vistas e ações entre Administrador e Utilizador).

league_provider.dart: Controla o estado em tempo real do campeonato, sincronizando a lista de equipas, plantéis de jogadores, pontuações e histórico de jogos.

theme_provider.dart: Controla a alternância global entre o Modo Escuro e o Modo Claro.

2. lib/pages/ (Ecrãs Principais / Camada de View)

Cada ficheiro nesta pasta representa uma interface ou ecrã inteiro que o utilizador visualiza ao navegar:

splash_page.dart: O ecrã de carregamento inicial (Splash Screen). Exibe o logótipo oficial do TUGOAL com um efeito de animação de arranque fluida enquanto prepara a base de dados e os serviços essenciais.

home_page.dart: O centro de controlo visual da app. Apresenta o menu de navegação por separadores (Notícias, Classificação, Equipas, Simulação), resumos das últimas jornadas e acessos rápidos.

news_page.dart: Aba dedicada ao feed de notícias do campeonato. Apresenta artigos, resumos e reportagens sobre os jogos ocorridos e destaques das jornadas.

standings_page.dart: Tabela de classificação em tempo real do campeonato com detalhe de pontos, jogos, vitórias, empates, derrotas, golos marcados, golos sofridos e diferença de golos.

teams_page.dart: Listagem de todas as equipas inscritas. Permite aceder à ficha técnica de cada clube e visualizar a constituição do plantel de jogadores.

team_detail_page.dart: Exibe a lista detalhada de jogadores de uma equipa especificando dados por atleta (golos, cartões, assistências) e permite ações de edição consoante o perfil de acesso.

simulation_page.dart: Interface interativa de simulação de jogos. Permite selecionar duas equipas, iniciar a partida simulada e visualizar o marcador e estatísticas geradas em tempo real.

admin_panel_page.dart: Painel reservado ao Administrador para inserção manual de resultados de jogos, criação/eliminação de equipas, adição/remoção de jogadores e publicação de notícias.

3. lib/widgets/ (Componentes Visuais Reutilizáveis)

Aloja pequenos blocos visuais modulares que são partilhados por múltiplos ecrãs para evitar duplicação de código:

team_card.dart: Cartão visual configurado para exibir o escudo, nome e métricas sumárias de uma equipa na grelha ou lista.

match_tile.dart: Componente de apresentação de resultados de jogos com marcadores, datas e estatísticas associadas.

custom_loader.dart: Indicador de carregamento animado utilizado durante o processamento de simulações ou pedidos assíncronos.

news_card.dart: Bloco visual formatado para exibição de destaques de notícias com imagem e resumo.

4. lib/models/ (Modelos de Dados / Camada de Dados)

Contém as classes Dart fortemente tipadas que estruturam os dados manipulados pela aplicação:

team.dart: Modelo representativo de uma equipa de futebol (ID, nome, escudo, estatísticas acumuladas, lista de jogadores).

player.dart: Modelo representativo de um jogador (ID, nome, posição, número de camisola, golos, cartões, equipa associada).

match.dart: Estrutura de dados para registo de partidas (equipa da casa, equipa visitante, golos marcados, faltas, remates, data e estado do jogo).

news.dart: Estrutura relativa aos artigos de notícias (título, conteúdo, data de publicação, jogo/equipa relata).

5. src_c/ (Módulos de Cálculo Algorítmico em C)

Contém as rotas de suporte escritas em C para processamento computacional de elevado desempenho:

simulation_engine.c: Algoritmo responsável pelo cálculo probabilístico dos resultados de simulação de partidas com base nas métricas e atributos das equipas.

6. lib/main.dart (O Ponto de Entrada)

O ficheiro mestre que arranca toda a aplicação. As suas funções são:

Inicializar o ciclo de vida global da app e bindings do Flutter.

Injetar e configurar os MultiProvider (Autenticação, Liga, Tema).

Definir as rotas de navegação internas da aplicação.

Definir a SplashPage como o ecrã de partida padrão.

Detalhe Técnico das Funcionalidades da App

Controlo de Permissões por Nível de Acesso (Perfis)

A aplicação adota um sistema rigoroso de controlo de acessos baseado em perfis:

Perfil Administrador: Acesso total às operações de escrita na base de dados, permitindo a criação e eliminação de equipas, adição e remoção de jogadores nos plantéis, inserção manual e retificação de resultados dos jogos ocorridos e publicação de artigos de notícia na respetiva aba.

Perfil Utilizador: Experiência orientada para a consulta interativa de estatísticas, acompanhamento das tabelas de classificação, leitura do feed de notícias e utilização livre do motor de simulação de jogos.

Gestão Dinâmica de Equipas e Plantéis

Criação e Remoção de Equipas: Permite parametrizar novas equipas no campeonato e remover estruturas obsoletas.

Gestão de Jogadores: Ferramentas administrativas para adicionar ou eliminar atletas dos plantéis de cada clube, mantendo o histórico individual de métricas (golos, cartões amarelos/vermelhos e jogos realizados).

Motor de Simulação de Jogos e Inserção Manual de Resultados

Simulação Algorítmica: O utilizador pode selecionar dois clubes e acionar o motor de simulação que calcula o resultado da partida, a distribuição de posse de bola, remates e ocorrência de golos.

Lançamento Manual de Resultados: O Administrador tem a capacidade de registar manualmente os marcadores oficiais dos jogos efetuados no campeonato, atualizando instantaneamente as classificações gerais.

Aba de Notícias do Campeonato

Secção dedicada ao acompanhamento informativo da competição. Exibe artigos e reportagens cobrindo os jogos ocorridos, sobressaindo momentos determinantes das jornadas e atualizações das equipas.

Sistema de Classificação e Atualização Estatística

Cálculo e atualização automática dos pontos (3 por vitória, 1 por empate, 0 por derrota), diferença de golos e registos de desempenho individual e coletivo logo após o fecho de qualquer jogo (simulado ou inserido manualmente).

Experiência Visual e UI (Interface de Utilizador)

A identidade visual do TUGOAL foi concebida para oferecer clareza na apresentação de dados desportivos:

Layout Adaptativo: Interface responsiva desenvolvida em Flutter que garante coerência visual em diferentes dimensões de ecrã móvel.

Identidade Gráfica: Utilização do logótipo oficial e paleta cromática desportiva contrastante, otimizada tanto para o modo claro como para o modo escuro.

Informação Institucional e Autoria

O projeto foi totalmente concebido e implementado no âmbito do ecossistema de engenharia de software do IPCA:

Estudante: Fábio Braga, n.º 36949

Unidade Curricular: Computação Movel

Curso: Aplicações Móveis

Data de Entrega: Maio de 2026